#!/usr/bin/env Rscript

# AWS Phase 2: Generate TTM Artifacts from S3 Data
# Standalone script for ECS task execution via Step Functions

# Use pre-built renv library installed during Docker build
.libPaths(c("/app/renv/library/linux-ubuntu-noble/R-4.4/x86_64-pc-linux-gnu", .libPaths()))

devtools::load_all("/app")

message("=== PHASE 2: GENERATE TTM ARTIFACTS (AWS) ===")
start_time <- Sys.time()

AWS_REGION <- Sys.getenv("AWS_REGION", "us-east-1")
S3_BUCKET <- Sys.getenv("S3_BUCKET")
SNS_TOPIC_ARN <- Sys.getenv("SNS_TOPIC_ARN")

if (S3_BUCKET == "") stop("S3_BUCKET environment variable is required")
if (SNS_TOPIC_ARN == "") stop("SNS_TOPIC_ARN environment variable is required")

message("Bucket: ", S3_BUCKET)
message("")

tryCatch({
  source("/app/scripts/run_phase2_generate.R")

  end_time <- Sys.time()
  duration <- round(as.numeric(difftime(end_time, start_time, units = "mins")), 2)

  generate_log <- if (exists("phase2_log")) phase2_log else create_pipeline_log()
  generate_success <- sum(generate_log$status == "success", na.rm = TRUE)
  generate_errors <- sum(generate_log$status == "error", na.rm = TRUE)
  generate_skipped <- sum(generate_log$status == "skipped", na.rm = TRUE)
  total_rows <- sum(generate_log$rows, na.rm = TRUE)

  # Upload pipeline log
  tryCatch({
    upload_pipeline_log(generate_log, S3_BUCKET, AWS_REGION)
  }, error = function(e) {
    warning("Failed to upload pipeline log: ", e$message)
  })

  # Send success notification
  etf_symbol <- Sys.getenv("ETF_SYMBOL", "QQQ")
  s3_key <- generate_s3_artifact_key(date = Sys.Date())

  success_message <- paste0(
    "TTM Pipeline Phase 2 completed!\n\n",
    "Configuration:\n",
    "  ETF: ", etf_symbol, "\n\n",
    "Results:\n",
    "  Success: ", generate_success, "\n",
    "  Errors:  ", generate_errors, "\n",
    "  Skipped: ", generate_skipped, "\n",
    "  Total rows: ", format(total_rows, big.mark = ","), "\n\n",
    "Duration: ", duration, " min\n\n",
    "Output: s3://", S3_BUCKET, "/", s3_key
  )

  tryCatch({
    send_pipeline_notification(
      topic_arn = SNS_TOPIC_ARN,
      subject = paste0("Pipeline Success: ", format(Sys.Date(), "%Y-%m-%d")),
      message = success_message,
      region = AWS_REGION
    )
  }, error = function(e) {
    warning("Failed to send success notification: ", e$message)
  })

  message("")
  message("=== PHASE 2 COMPLETE ===")
  message("Success: ", generate_success, " | Errors: ", generate_errors,
          " | Skipped: ", generate_skipped, " | Duration: ", duration, " min")

}, error = function(e) {
  error_msg <- paste0("Phase 2 (Generate) failed: ", e$message)
  message(error_msg)

  tryCatch({
    send_pipeline_notification(
      topic_arn = SNS_TOPIC_ARN,
      subject = "Pipeline Failed: Phase 2 (Generate)",
      message = error_msg,
      region = AWS_REGION
    )
  }, error = function(e2) {
    warning("Failed to send error notification: ", e2$message)
  })

  stop(error_msg)
})
