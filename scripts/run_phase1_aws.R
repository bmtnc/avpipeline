#!/usr/bin/env Rscript

# AWS Phase 1: Fetch Raw Data to S3
# Standalone script for ECS task execution via Step Functions

# Use pre-built renv library installed during Docker build
.libPaths(c("/app/renv/library/linux-ubuntu-noble/R-4.4/x86_64-pc-linux-gnu", .libPaths()))

devtools::load_all("/app")

message("=== PHASE 1: FETCH RAW DATA (AWS) ===")
start_time <- Sys.time()

AWS_REGION <- Sys.getenv("AWS_REGION", "us-east-1")
S3_BUCKET <- Sys.getenv("S3_BUCKET")
SNS_TOPIC_ARN <- Sys.getenv("SNS_TOPIC_ARN")

if (S3_BUCKET == "") stop("S3_BUCKET environment variable is required")
if (SNS_TOPIC_ARN == "") stop("SNS_TOPIC_ARN environment variable is required")

etf_symbol <- Sys.getenv("ETF_SYMBOL", "QQQ")
fetch_mode <- Sys.getenv("FETCH_MODE", "full")

message("ETF: ", etf_symbol, " | Bucket: ", S3_BUCKET, " | Mode: ", fetch_mode)
message("")

tryCatch({
  source("/app/scripts/run_phase1_fetch.R")

  end_time <- Sys.time()
  duration <- round(as.numeric(difftime(end_time, start_time, units = "mins")), 2)

  fetch_log <- if (exists("phase1_log")) phase1_log else create_pipeline_log()
  fetch_success <- sum(fetch_log$status == "success", na.rm = TRUE)
  fetch_errors <- sum(fetch_log$status == "error", na.rm = TRUE)
  fetch_skipped <- sum(fetch_log$status == "skipped", na.rm = TRUE)

  message("")
  message("=== PHASE 1 COMPLETE ===")
  message("Success: ", fetch_success, " | Errors: ", fetch_errors,
          " | Skipped: ", fetch_skipped, " | Duration: ", duration, " min")

}, error = function(e) {
  error_msg <- paste0("Phase 1 (Fetch) failed: ", e$message)
  message(error_msg)

  tryCatch({
    send_pipeline_notification(
      topic_arn = SNS_TOPIC_ARN,
      subject = "Pipeline Failed: Phase 1 (Fetch)",
      message = error_msg,
      region = AWS_REGION
    )
  }, error = function(e2) {
    warning("Failed to send error notification: ", e2$message)
  })

  stop(error_msg)
})
