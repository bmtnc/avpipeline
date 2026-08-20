#!/usr/bin/env Rscript

# AWS Phase 2: Generate TTM Artifacts from S3 Data
# Standalone script for ECS task execution via Step Functions

# Use pre-built renv library installed during Docker build
.libPaths(c(
  "/app/renv/library/linux-ubuntu-noble/R-4.4/x86_64-pc-linux-gnu",
  .libPaths()
))

devtools::load_all("/app")

message("=== PHASE 2: GENERATE TTM ARTIFACTS (AWS) ===")
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

message("Bucket: ", S3_BUCKET)
message("")

tryCatch(
  {
    source("/app/scripts/run_phase2_generate.R")

    end_time <- Sys.time()
    duration <- round(
      as.numeric(difftime(end_time, start_time, units = "mins")),
      2
    )

    # Fail loudly rather than falling back to an empty log. The old `exists()`
    # fallback failed open to zeros, so the notification kept arriving and
    # looked plausible while reporting nothing.
    if (!exists("phase2_summary")) {
      stop(
        "run_phase2_generate.R did not produce phase2_summary; ",
        "cannot report Phase 2 results"
      )
    }

    generate_log <- if (exists("phase2_log")) {
      phase2_log
    } else {
      create_pipeline_log()
    }

    # Skip the upload when empty (e.g. price-only runs) so it can't clobber a
    # real log written earlier the same day.
    if (nrow(generate_log) > 0) {
      tryCatch(
        {
          upload_pipeline_log(
            generate_log,
            S3_BUCKET,
            AWS_REGION,
            filename = "phase2_log.parquet"
          )
        },
        error = function(e) {
          warning("Failed to upload pipeline log: ", e$message)
        }
      )
    } else {
      message("Pipeline log is empty; skipping upload.")
    }

    failed_block <- if (length(phase2_summary$failed_tickers) > 0) {
      paste0(
        "Failed tickers (first 20):\n  ",
        paste(
          utils::head(phase2_summary$failed_tickers, 20),
          collapse = ", "
        ),
        "\n\n"
      )
    } else {
      ""
    }

    success_message <- paste0(
      "TTM Pipeline Phase 2 completed!\n\n",
      "Configuration:\n",
      "  Mode: ",
      phase2_summary$mode,
      "\n\n",
      "Results:\n",
      "  Tickers processed: ",
      phase2_summary$tickers,
      "\n",
      "  Success: ",
      phase2_summary$success,
      "\n",
      "  Errors:  ",
      phase2_summary$errors,
      "\n",
      "  Skipped: ",
      phase2_summary$skipped,
      "\n\n",
      failed_block,
      "Artifacts:\n",
      "  Quarterly: ",
      format(phase2_summary$quarterly_rows, big.mark = ","),
      " rows\n             s3://",
      S3_BUCKET,
      "/",
      phase2_summary$quarterly_s3_key,
      "\n",
      "  Price:     ",
      format(phase2_summary$price_rows, big.mark = ","),
      " rows\n             s3://",
      S3_BUCKET,
      "/",
      phase2_summary$price_s3_key,
      "\n\n",
      "Duration: ",
      duration,
      " min"
    )

    subject_suffix <- if (phase2_summary$errors > 0) {
      paste0(" (", phase2_summary$errors, " errors)")
    } else {
      ""
    }

    tryCatch(
      {
        send_pipeline_notification(
          topic_arn = SNS_TOPIC_ARN,
          subject = paste0(
            "Pipeline Success: Phase 2 ",
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
    message("=== PHASE 2 COMPLETE ===")
    message(
      "Success: ",
      phase2_summary$success,
      " | Errors: ",
      phase2_summary$errors,
      " | Skipped: ",
      phase2_summary$skipped,
      " | Duration: ",
      duration,
      " min"
    )
  },
  error = function(e) {
    error_msg <- paste0("Phase 2 (Generate) failed: ", e$message)
    message(error_msg)

    tryCatch(
      {
        send_pipeline_notification(
          topic_arn = SNS_TOPIC_ARN,
          subject = "Pipeline Failed: Phase 2 (Generate)",
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
