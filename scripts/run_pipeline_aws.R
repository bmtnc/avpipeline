#!/usr/bin/env Rscript

# AWS Pipeline Orchestration Script (Two-Phase Architecture)
# Phase 1: Fetch raw data to S3 with smart refresh
# Phase 2: Generate TTM artifacts from S3 data

# Use pre-built renv library installed during Docker build
.libPaths(c("/app/renv/library/linux-ubuntu-noble/R-4.4/x86_64-pc-linux-gnu", .libPaths()))

# Load package functions
devtools::load_all("/app")

message("=== Starting AWS Pipeline Execution (Two-Phase) ===")
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

message(paste0("AWS Region: ", AWS_REGION))
message(paste0("S3 Bucket: ", S3_BUCKET))

# Step 1: Phase 1 - Fetch raw data to S3
message("\n[1/3] Phase 1: Fetching raw data to S3...")
phase1_success <- FALSE
tryCatch({
  source("/app/scripts/run_phase1_fetch.R")
  message("Phase 1 completed successfully")
  phase1_success <- TRUE
}, error = function(e) {
  error_msg <- paste0("Phase 1 (Fetch) failed: ", e$message)
  message(error_msg)
  send_pipeline_notification(
    topic_arn = SNS_TOPIC_ARN,
    subject = "Pipeline Failed: Phase 1 (Fetch)",
    message = error_msg,
    region = AWS_REGION
  )
  stop(error_msg)
})

phase1_time <- Sys.time()
phase1_duration <- round(as.numeric(difftime(phase1_time, start_time, units = "mins")), 2)

# Step 2: Phase 2 - Generate TTM artifacts
message("\n[2/3] Phase 2: Generating TTM artifacts...")
phase2_success <- FALSE
tryCatch({
  source("/app/scripts/run_phase2_generate.R")
  message("Phase 2 completed successfully")
  phase2_success <- TRUE
}, error = function(e) {
  error_msg <- paste0("Phase 2 (Generate) failed: ", e$message)
  message(error_msg)
  send_pipeline_notification(
    topic_arn = SNS_TOPIC_ARN,
    subject = "Pipeline Failed: Phase 2 (Generate)",
    message = error_msg,
    region = AWS_REGION
  )
  stop(error_msg)
})

phase2_time <- Sys.time()
phase2_duration <- round(as.numeric(difftime(phase2_time, phase1_time, units = "mins")), 2)

# Step 3: Send success notification
message("\n[3/3] Sending success notification...")
end_time <- Sys.time()
total_duration <- round(as.numeric(difftime(end_time, start_time, units = "mins")), 2)

s3_key <- generate_s3_artifact_key(date = Sys.Date())

success_message <- paste0(
  "TTM Pipeline completed successfully!\n\n",
  "Execution Time:\n",
  "  Phase 1 (Fetch): ", phase1_duration, " minutes\n",
  "  Phase 2 (Generate): ", phase2_duration, " minutes\n",
  "  Total: ", total_duration, " minutes\n\n",
  "Date: ", format(Sys.Date(), "%Y-%m-%d"), "\n",
  "S3 Location: s3://", S3_BUCKET, "/", s3_key, "\n\n",
  "The financial data artifact has been updated and is ready for analysis."
)

tryCatch({
  send_pipeline_notification(
    topic_arn = SNS_TOPIC_ARN,
    subject = paste0("Pipeline Success: ", format(Sys.Date(), "%Y-%m-%d")),
    message = success_message,
    region = AWS_REGION
  )
  message("Success notification sent")
}, error = function(e) {
  warning(paste0("Failed to send success notification: ", e$message))
})

message("\n=== Pipeline Execution Complete ===")
message(paste0("Phase 1 (Fetch): ", phase1_duration, " minutes"))
message(paste0("Phase 2 (Generate): ", phase2_duration, " minutes"))
message(paste0("Total execution time: ", total_duration, " minutes"))
