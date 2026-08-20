#!/usr/bin/env Rscript

# AWS Pipeline Orchestration Script (Two-Phase Architecture)
# Phase 1: Fetch raw data to S3 with smart refresh
# Phase 2: Generate TTM artifacts from S3 data

# Use pre-built renv library installed during Docker build
.libPaths(c(
  "/app/renv/library/linux-ubuntu-noble/R-4.4/x86_64-pc-linux-gnu",
  .libPaths()
))

# Load package functions
devtools::load_all("/app")

message("=== Starting AWS Pipeline Execution ===")
start_time <- Sys.time()

# AWS configuration from environment variables
AWS_REGION <- Sys.getenv("AWS_REGION", "us-east-1")
S3_BUCKET <- Sys.getenv("S3_BUCKET")
SNS_TOPIC_ARN <- Sys.getenv("SNS_TOPIC_ARN")

# Validate environment variables
if (S3_BUCKET == "") {
  stop("S3_BUCKET environment variable is required")
}

if (SNS_TOPIC_ARN == "") {
  stop("SNS_TOPIC_ARN environment variable is required")
}

message("Region: ", AWS_REGION, " | Bucket: ", S3_BUCKET)
message("")

# Step 1: Phase 1 - Fetch raw data to S3
message("[1/3] Running Phase 1...")
phase1_success <- FALSE
tryCatch(
  {
    source("/app/scripts/run_phase1_fetch.R")
    phase1_success <- TRUE
  },
  error = function(e) {
    error_msg <- paste0("Phase 1 (Fetch) failed: ", e$message)
    message(error_msg)
    send_pipeline_notification(
      topic_arn = SNS_TOPIC_ARN,
      subject = "Pipeline Failed: Phase 1 (Fetch)",
      message = error_msg,
      region = AWS_REGION
    )
    stop(error_msg)
  }
)

phase1_time <- Sys.time()
phase1_duration <- round(
  as.numeric(difftime(phase1_time, start_time, units = "mins")),
  2
)

# Step 2: Phase 2 - Generate TTM artifacts
message("")
message("[2/3] Running Phase 2...")
phase2_success <- FALSE
tryCatch(
  {
    source("/app/scripts/run_phase2_generate.R")
    phase2_success <- TRUE
  },
  error = function(e) {
    error_msg <- paste0("Phase 2 (Generate) failed: ", e$message)
    message(error_msg)
    send_pipeline_notification(
      topic_arn = SNS_TOPIC_ARN,
      subject = "Pipeline Failed: Phase 2 (Generate)",
      message = error_msg,
      region = AWS_REGION
    )
    stop(error_msg)
  }
)

phase2_time <- Sys.time()
phase2_duration <- round(
  as.numeric(difftime(phase2_time, phase1_time, units = "mins")),
  2
)

# Step 3: Upload combined log and send notification
message("")
message("[3/3] Finalizing...")

# Combine logs from both phases. The previous if/else-if picked ONE log, so the
# fetch and generate blocks could never both be populated.
combined_log <- dplyr::bind_rows(
  if (exists("phase1_log")) phase1_log else create_pipeline_log(),
  if (exists("phase2_log")) phase2_log else create_pipeline_log()
)

# Upload log to S3
tryCatch(
  {
    upload_pipeline_log(combined_log, S3_BUCKET, AWS_REGION)
  },
  error = function(e) {
    warning("Failed to upload pipeline log: ", e$message)
  }
)

end_time <- Sys.time()
total_duration <- round(
  as.numeric(difftime(end_time, start_time, units = "mins")),
  2
)

# Both phases have succeeded by this point, so a failure while BUILDING the
# report must still notify. Without this wrapper a missing summary would abort
# the script silently — no success mail, no failure mail — which is the exact
# failure mode this reporting rework exists to remove.
tryCatch(
  {
    if (!exists("phase1_summary")) {
      stop(
        "run_phase1_fetch.R did not produce phase1_summary; ",
        "cannot report Phase 1 results"
      )
    }
    if (!exists("phase2_summary")) {
      stop(
        "run_phase2_generate.R did not produce phase2_summary; ",
        "cannot report Phase 2 results"
      )
    }

    success_message <- paste0(
      "TTM Pipeline completed!\n\n",
      "Configuration:\n",
      "  ETF: ",
      phase1_summary$etf,
      "\n",
      "  Fetch mode:   ",
      phase1_summary$mode,
      "\n",
      "  Phase 2 mode: ",
      phase2_summary$mode,
      "\n\n",
      "Phase 1 (Fetch): ",
      phase1_summary$tickers,
      " tickers\n",
      "  Success: ",
      phase1_summary$success,
      "\n",
      "  Errors:  ",
      phase1_summary$errors,
      "\n",
      "  Skipped: ",
      phase1_summary$skipped,
      "\n\n",
      "Phase 2 (Generate): ",
      phase2_summary$tickers,
      " tickers\n",
      "  Success: ",
      phase2_summary$success,
      "\n",
      "  Errors:  ",
      phase2_summary$errors,
      "\n",
      "  Skipped: ",
      phase2_summary$skipped,
      "\n\n",
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
      "Timing:\n",
      "  Phase 1: ",
      phase1_duration,
      " min\n",
      "  Phase 2: ",
      phase2_duration,
      " min\n",
      "  Total:   ",
      total_duration,
      " min"
    )

    total_errors <- phase1_summary$errors + phase2_summary$errors
    subject_suffix <- if (total_errors > 0) {
      paste0(" (", total_errors, " errors)")
    } else {
      ""
    }

    send_pipeline_notification(
      topic_arn = SNS_TOPIC_ARN,
      subject = paste0(
        "Pipeline Success: ",
        format(Sys.Date(), "%Y-%m-%d"),
        subject_suffix
      ),
      message = success_message,
      region = AWS_REGION
    )
    message("Notification sent")
  },
  error = function(e) {
    error_msg <- paste0("Pipeline finalize failed: ", conditionMessage(e))
    message(error_msg)

    tryCatch(
      {
        send_pipeline_notification(
          topic_arn = SNS_TOPIC_ARN,
          subject = "Pipeline Failed: Finalize",
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

message("")
message("=== PIPELINE COMPLETE ===")
message(
  "Phase 1: ",
  phase1_duration,
  " min | Phase 2: ",
  phase2_duration,
  " min | Total: ",
  total_duration,
  " min"
)
