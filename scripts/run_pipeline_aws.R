#!/usr/bin/env Rscript

# AWS Pipeline Orchestration Script
# This script runs the complete TTM pipeline in AWS ECS and uploads results to S3

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

message(paste0("AWS Region: ", AWS_REGION))
message(paste0("S3 Bucket: ", S3_BUCKET))

# Step 1: Retrieve API key from Parameter Store
message("\n[1/4] Retrieving API key from Parameter Store...")
tryCatch({
  api_key <- get_api_key_from_parameter_store(
    parameter_name = "/avpipeline/alpha-vantage-api-key",
    region = AWS_REGION
  )
  Sys.setenv(ALPHA_VANTAGE_API_KEY = api_key)
  message("API key retrieved successfully")
}, error = function(e) {
  error_msg <- paste0("Failed to retrieve API key: ", e$message)
  message(error_msg)
  send_pipeline_notification(
    topic_arn = SNS_TOPIC_ARN,
    subject = "Pipeline Failed: API Key Retrieval",
    message = error_msg,
    region = AWS_REGION
  )
  stop(error_msg)
})

# Step 2: Run the main pipeline
message("\n[2/4] Running TTM pipeline...")
pipeline_success <- FALSE
tryCatch({
  source("/app/scripts/build_complete_ttm_pipeline.R")
  message("Pipeline completed successfully")
  pipeline_success <- TRUE
}, error = function(e) {
  error_msg <- paste0("Pipeline execution failed: ", e$message)
  message(error_msg)
  send_pipeline_notification(
    topic_arn = SNS_TOPIC_ARN,
    subject = "Pipeline Failed: Execution Error",
    message = error_msg,
    region = AWS_REGION
  )
  stop(error_msg)
})

# Step 3: Upload artifact to S3
message("\n[3/4] Uploading artifact to S3...")
local_artifact_path <- "/app/cache/ttm_per_share_financial_artifact.parquet"

if (!file.exists(local_artifact_path)) {
  error_msg <- paste0("Artifact file not found: ", local_artifact_path)
  message(error_msg)
  send_pipeline_notification(
    topic_arn = SNS_TOPIC_ARN,
    subject = "Pipeline Failed: Artifact Not Found",
    message = error_msg,
    region = AWS_REGION
  )
  stop(error_msg)
}

tryCatch({
  s3_key <- generate_s3_artifact_key(date = Sys.Date())
  upload_artifact_to_s3(
    local_path = local_artifact_path,
    bucket_name = S3_BUCKET,
    s3_key = s3_key,
    region = AWS_REGION
  )
  message("Artifact uploaded successfully")
}, error = function(e) {
  error_msg <- paste0("Failed to upload artifact: ", e$message)
  message(error_msg)
  send_pipeline_notification(
    topic_arn = SNS_TOPIC_ARN,
    subject = "Pipeline Failed: S3 Upload Error",
    message = error_msg,
    region = AWS_REGION
  )
  stop(error_msg)
})

# Step 4: Send success notification
message("\n[4/4] Sending success notification...")
end_time <- Sys.time()
duration <- round(as.numeric(difftime(end_time, start_time, units = "mins")), 2)

success_message <- paste0(
  "TTM Pipeline completed successfully!\n\n",
  "Execution Time: ", duration, " minutes\n",
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
message(paste0("Total execution time: ", duration, " minutes"))
