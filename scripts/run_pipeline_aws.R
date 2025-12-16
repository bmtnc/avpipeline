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
fetch_log <- combined_log[combined_log$phase == "fetch", ]
generate_log <- combined_log[combined_log$phase == "generate", ]

fetch_success <- sum(fetch_log$status == "success", na.rm = TRUE)
fetch_errors <- sum(fetch_log$status == "error", na.rm = TRUE)
fetch_skipped <- sum(fetch_log$status == "skipped", na.rm = TRUE)
fetch_total <- fetch_success + fetch_errors + fetch_skipped

generate_success <- sum(generate_log$status == "success", na.rm = TRUE)
generate_errors <- sum(generate_log$status == "error", na.rm = TRUE)
generate_skipped <- sum(generate_log$status == "skipped", na.rm = TRUE)
generate_total <- generate_success + generate_errors + generate_skipped

total_rows <- sum(generate_log$rows, na.rm = TRUE)

etf_symbol <- Sys.getenv("ETF_SYMBOL", "QQQ")
fetch_mode <- Sys.getenv("FETCH_MODE", "full")

s3_key <- generate_s3_artifact_key(date = Sys.Date())

success_message <- paste0(
  "TTM Pipeline completed!\n\n",
  "Configuration:\n",
  "  ETF: ", etf_symbol, "\n",
  "  Mode: ", fetch_mode, "\n\n",
  "Phase 1 (Fetch): ", fetch_total, " tickers\n",
  "  Success: ", fetch_success, "\n",
  "  Errors:  ", fetch_errors, "\n",
  "  Skipped: ", fetch_skipped, "\n\n",
  "Phase 2 (Generate): ", generate_total, " tickers\n",
  "  Success: ", generate_success, "\n",
  "  Errors:  ", generate_errors, "\n",
  "  Skipped: ", generate_skipped, "\n",
  "  Total rows: ", format(total_rows, big.mark = ","), "\n\n",
  "Timing:\n",
  "  Phase 1: ", phase1_duration, " min\n",
  "  Phase 2: ", phase2_duration, " min\n",
  "  Total:   ", total_duration, " min\n\n",
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
