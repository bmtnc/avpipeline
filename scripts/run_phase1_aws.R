#!/usr/bin/env Rscript

# AWS Phase 1: Fetch Raw Data to S3
# Standalone script for ECS task execution via Step Functions

# Use pre-built renv library installed during Docker build
.libPaths(c(
  "/app/renv/library/linux-ubuntu-noble/R-4.4/x86_64-pc-linux-gnu",
  .libPaths()
))

devtools::load_all("/app")

message("=== PHASE 1: FETCH RAW DATA (AWS) ===")
start_time <- Sys.time()

AWS_REGION <- Sys.getenv("AWS_REGION", "us-east-1")
S3_BUCKET <- Sys.getenv("S3_BUCKET")
SNS_TOPIC_ARN <- Sys.getenv("SNS_TOPIC_ARN")

if (S3_BUCKET == "") {
  stop("S3_BUCKET environment variable is required")
}
if (SNS_TOPIC_ARN == "") {
  stop("SNS_TOPIC_ARN environment variable is required")
}

etf_symbol <- Sys.getenv("ETF_SYMBOL", "QQQ")
fetch_mode <- Sys.getenv("FETCH_MODE", "full")

# Sourcing run_phase1_fetch.R rebinds etf_symbol/fetch_mode in the global env,
# and bulk_interim rewrites FETCH_MODE before sourcing. Keep the mode that was
# actually requested so the notification reports the scheduled run, not the
# internal fetch it delegated to.
requested_fetch_mode <- fetch_mode

message("ETF: ", etf_symbol, " | Bucket: ", S3_BUCKET, " | Mode: ", fetch_mode)
message("")

tryCatch(
  {
    # The daily run (bulk_interim) does two things: fast bulk-quote price interim,
    # then the smart quarterly fetch so new earnings are picked up the day they
    # post (writing the Phase 1 manifest). Per-ticker price/splits backfill stays
    # on the weekly full run. All other modes run the per-ticker fetch directly.
    if (fetch_mode == "bulk_interim") {
      source("/app/scripts/run_phase1_interim_prices.R")
      Sys.setenv(FETCH_MODE = "quarterly_only")
      source("/app/scripts/run_phase1_fetch.R")
    } else {
      source("/app/scripts/run_phase1_fetch.R")
    }

    end_time <- Sys.time()
    duration <- round(
      as.numeric(difftime(end_time, start_time, units = "mins")),
      2
    )

    if (!exists("phase1_summary")) {
      stop(
        "run_phase1_fetch.R did not produce phase1_summary; ",
        "cannot report Phase 1 results"
      )
    }

    fetch_log <- if (exists("phase1_log")) phase1_log else create_pipeline_log()

    # Phase 1 previously computed this log and threw it away. Written under its
    # own filename so the Phase 2 task can't overwrite it.
    if (nrow(fetch_log) > 0) {
      tryCatch(
        {
          upload_pipeline_log(
            fetch_log,
            S3_BUCKET,
            AWS_REGION,
            filename = "phase1_log.parquet"
          )
        },
        error = function(e) {
          warning("Failed to upload pipeline log: ", e$message)
        }
      )
    } else {
      message("Pipeline log is empty; skipping upload.")
    }

    # bulk_interim runs two legs; report the price leg explicitly so a run that
    # quoted nothing can't hide behind the quarterly leg's success counts.
    interim_block <- if (exists("interim_summary")) {
      paste0(
        "Interim prices (bulk quotes):\n",
        "  Rows: ",
        format(interim_summary$rows, big.mark = ","),
        " across ",
        interim_summary$tickers,
        " tickers, ",
        interim_summary$trading_days,
        " trading day(s)\n",
        if (interim_summary$rows == 0) {
          "  WARNING: no interim quotes stored this run\n"
        } else {
          ""
        },
        "\n"
      )
    } else {
      ""
    }

    failed_block <- if (length(phase1_summary$failed_tickers) > 0) {
      paste0(
        "Failed tickers (first 20):\n  ",
        paste(
          utils::head(phase1_summary$failed_tickers, 20),
          collapse = ", "
        ),
        "\n\n"
      )
    } else {
      ""
    }

    success_message <- paste0(
      "TTM Pipeline Phase 1 completed!\n\n",
      "Configuration:\n",
      "  ETF:  ",
      phase1_summary$etf,
      "\n",
      "  Mode: ",
      requested_fetch_mode,
      "\n\n",
      "Results:\n",
      "  Tickers processed: ",
      phase1_summary$tickers,
      "\n",
      "  Success: ",
      phase1_summary$success,
      "\n",
      "  Errors:  ",
      phase1_summary$errors,
      "\n",
      "  Skipped: ",
      phase1_summary$skipped,
      "\n\n",
      interim_block,
      failed_block,
      "Raw data: s3://",
      S3_BUCKET,
      "/raw/\n\n",
      "Duration: ",
      duration,
      " min"
    )

    subject_suffix <- if (phase1_summary$errors > 0) {
      paste0(" (", phase1_summary$errors, " errors)")
    } else {
      ""
    }

    tryCatch(
      {
        send_pipeline_notification(
          topic_arn = SNS_TOPIC_ARN,
          subject = paste0(
            "Pipeline Success: Phase 1 ",
            format(Sys.Date(), "%Y-%m-%d"),
            subject_suffix
          ),
          message = success_message,
          region = AWS_REGION
        )
      },
      error = function(e) {
        warning("Failed to send success notification: ", e$message)
      }
    )

    message("")
    message("=== PHASE 1 COMPLETE ===")
    message(
      "Success: ",
      phase1_summary$success,
      " | Errors: ",
      phase1_summary$errors,
      " | Skipped: ",
      phase1_summary$skipped,
      " | Duration: ",
      duration,
      " min"
    )
  },
  error = function(e) {
    error_msg <- paste0("Phase 1 (Fetch) failed: ", e$message)
    message(error_msg)

    tryCatch(
      {
        send_pipeline_notification(
          topic_arn = SNS_TOPIC_ARN,
          subject = "Pipeline Failed: Phase 1 (Fetch)",
          message = error_msg,
          region = AWS_REGION
        )
      },
      error = function(e2) {
        warning("Failed to send error notification: ", e2$message)
      }
    )

    stop(error_msg)
  }
)
