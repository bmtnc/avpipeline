#!/usr/bin/env Rscript

# ============================================================================
# Phase 2: Generate TTM Artifacts from S3 Raw Data
# ============================================================================
# Reads raw data from S3 and generates the TTM per-share financial artifact.
#
# Input: s3://{bucket}/raw/{TICKER}/*.parquet
# Output: s3://{bucket}/ttm-artifacts/{YYYY-MM-DD}/ttm_per_share_financial_artifact.parquet
# ============================================================================

devtools::load_all()

# ============================================================================
# CONFIGURATION
# ============================================================================

start_date_str <- Sys.getenv("START_DATE", "2004-12-31")
start_date <- as.Date(start_date_str)
aws_region <- Sys.getenv("AWS_REGION", "us-east-1")
s3_bucket <- Sys.getenv("S3_BUCKET")

if (s3_bucket == "") {
  stop("S3_BUCKET environment variable is required")
}

threshold <- 4
lookback <- 5
lookahead <- 5
end_window_size <- 5
end_threshold <- 3
min_obs <- 10

phase_start_time <- Sys.time()
log_phase_start("PHASE 2: GENERATE TTM ARTIFACTS",
  sprintf("Start date: %s | Bucket: %s", start_date, s3_bucket)
)

# ============================================================================
# SETUP
# ============================================================================

# Get all tickers with data in S3 (includes current + historical ETF members)
all_tickers <- s3_list_existing_tickers(s3_bucket, aws_region)

# Load checkpoint and filter to unprocessed tickers
checkpoint <- s3_read_checkpoint(s3_bucket, "phase2", aws_region)
already_processed <- checkpoint$processed_tickers %||% character(0)
tickers <- setdiff(all_tickers, already_processed)
n_tickers <- length(tickers)
n_total <- length(all_tickers)

log_pipeline(sprintf("Tickers in S3: %d total, %d remaining", n_total, n_tickers))

if (length(already_processed) > 0) {
  log_pipeline(sprintf("Resuming from checkpoint: %d already processed", length(already_processed)))
}

# ============================================================================
# PROCESS TICKERS
# ============================================================================

final_artifact <- tibble::tibble()
pipeline_log <- if (exists("phase1_log")) phase1_log else create_pipeline_log()
success_count <- 0
error_count <- 0
skip_count <- 0

for (i in seq_along(tickers)) {
  ticker <- tickers[i]
  ticker_start <- Sys.time()

  tryCatch({
    result <- process_ticker_from_s3(
      ticker = ticker,
      bucket_name = s3_bucket,
      start_date = start_date,
      region = aws_region,
      threshold = threshold,
      lookback = lookback,
      lookahead = lookahead,
      end_window_size = end_window_size,
      end_threshold = end_threshold,
      min_obs = min_obs
    )

    duration <- as.numeric(difftime(Sys.time(), ticker_start, units = "secs"))

    if (!is.null(result) && nrow(result) > 0) {
      success_count <- success_count + 1
      final_artifact <- dplyr::bind_rows(final_artifact, result)
      checkpoint <- update_checkpoint(checkpoint, ticker, success = TRUE)
      pipeline_log <- add_log_entry(
        pipeline_log, ticker, "generate", "ttm", "success",
        rows = nrow(result), duration_seconds = duration
      )
    } else {
      skip_count <- skip_count + 1
      checkpoint <- update_checkpoint(checkpoint, ticker, success = TRUE)
      pipeline_log <- add_log_entry(
        pipeline_log, ticker, "generate", "ttm", "skipped",
        error_message = "No data returned", duration_seconds = duration
      )
    }

    # Log progress and save checkpoint every 10 tickers
    if (i %% 10 == 0) {
      log_progress_summary(i, n_tickers, success_count, error_count, "Generate")
      s3_write_checkpoint(checkpoint, s3_bucket, "phase2", aws_region)
      gc(verbose = FALSE)
    }
    if (i %% 50 == 0) gc(full = TRUE, verbose = FALSE)

  }, error = function(e) {
    error_count <<- error_count + 1
    log_error(ticker, conditionMessage(e))
    checkpoint <<- update_checkpoint(checkpoint, ticker, success = FALSE)
    pipeline_log <<- add_log_entry(
      pipeline_log, ticker, "generate", "ttm", "error",
      error_message = conditionMessage(e),
      duration_seconds = as.numeric(difftime(Sys.time(), ticker_start, units = "secs"))
    )
  })
}

# ============================================================================
# UPLOAD ARTIFACT TO S3
# ============================================================================

log_pipeline("Uploading TTM artifact to S3...")

local_artifact_path <- tempfile(fileext = ".parquet")
on.exit(unlink(local_artifact_path), add = TRUE)

arrow::write_parquet(final_artifact, local_artifact_path)

s3_key <- generate_s3_artifact_key(date = Sys.Date())
upload_artifact_to_s3(
  local_path = local_artifact_path,
  bucket_name = s3_bucket,
  s3_key = s3_key,
  region = aws_region
)

log_pipeline(sprintf("Artifact: s3://%s/%s (%d rows)", s3_bucket, s3_key, nrow(final_artifact)))

# Clear checkpoint on successful completion
s3_clear_checkpoint(s3_bucket, "phase2", aws_region)
log_pipeline("Checkpoint cleared (phase complete)")

# ============================================================================
# SUMMARY
# ============================================================================

phase_duration <- as.numeric(difftime(Sys.time(), phase_start_time, units = "secs"))
log_phase_end("PHASE 2: GENERATE TTM ARTIFACTS",
  total = n_tickers,
  successful = success_count + skip_count,
  failed = error_count,
  duration_seconds = phase_duration
)

# Return log for use by run_pipeline_aws.R
phase2_log <- pipeline_log
