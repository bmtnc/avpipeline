#!/usr/bin/env Rscript

# AWS Pipeline Orchestration Script (Two-Phase Architecture)
# Phase 1: Fetch raw data to S3 with smart refresh
# Phase 2: Generate TTM artifacts from S3 data

# Use pre-built renv library installed during Docker build
.libPaths(c("/app/renv/library/linux-ubuntu-noble/R-4.4/x86_64-pc-linux-gnu", .libPaths()))

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
tryCatch({
  source("/app/scripts/run_phase1_fetch.R")
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
message("")
message("[2/3] Running Phase 2...")
phase2_success <- FALSE
tryCatch({
  source("/app/scripts/run_phase2_generate.R")
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

# Step 3: Upload combined log and send notification
message("")
message("[3/3] Finalizing...")

# Combine logs from both phases
combined_log <- if (exists("phase2_log")) {
  phase2_log
} else if (exists("phase1_log")) {
  phase1_log
} else {
  create_pipeline_log()
}

# Upload log to S3
tryCatch({
  upload_pipeline_log(combined_log, S3_BUCKET, AWS_REGION)
}, error = function(e) {
  warning("Failed to upload pipeline log: ", e$message)
})

end_time <- Sys.time()
total_duration <- round(as.numeric(difftime(end_time, start_time, units = "mins")), 2)

# Calculate summary stats from log
fetch_success <- sum(combined_log$phase == "fetch" & combined_log$status == "success")
fetch_errors <- sum(combined_log$phase == "fetch" & combined_log$status == "error")
generate_success <- sum(combined_log$phase == "generate" & combined_log$status == "success")
generate_errors <- sum(combined_log$phase == "generate" & combined_log$status == "error")
total_rows <- sum(combined_log$rows[combined_log$phase == "generate"], na.rm = TRUE)

s3_key <- generate_s3_artifact_key(date = Sys.Date())

success_message <- paste0(
  "TTM Pipeline completed!\n\n",
  "Summary:\n",
  "  Phase 1: ", fetch_success, " fetched, ", fetch_errors, " errors\n",
  "  Phase 2: ", generate_success, " processed, ", generate_errors, " errors\n",
  "  Total rows: ", total_rows, "\n\n",
  "Timing:\n",
  "  Phase 1: ", phase1_duration, " min\n",
  "  Phase 2: ", phase2_duration, " min\n",
  "  Total: ", total_duration, " min\n\n",
  "Output: s3://", S3_BUCKET, "/", s3_key
)

tryCatch({
  send_pipeline_notification(
    topic_arn = SNS_TOPIC_ARN,
    subject = paste0("Pipeline Success: ", format(Sys.Date(), "%Y-%m-%d")),
    message = success_message,
    region = AWS_REGION
  )
  message("Notification sent")
}, error = function(e) {
  warning("Failed to send notification: ", e$message)
})

message("")
message("=== PIPELINE COMPLETE ===")
message("Phase 1: ", phase1_duration, " min | Phase 2: ", phase2_duration, " min | Total: ", total_duration, " min")
