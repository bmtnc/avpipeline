#!/usr/bin/env Rscript

# ============================================================================
# Phase 2: Generate Quarterly TTM and Price Artifacts from S3 Raw Data
# ============================================================================
# Loads all raw data using Arrow datasets, processes each ticker for quarterly
# TTM metrics, and outputs two separate artifacts:
#   1. ttm_quarterly_artifact.parquet - Quarterly frequency TTM financials
#   2. price_artifact.parquet - Daily prices (cleaned)
#
# The daily TTM artifact (with forward-fill and per-share metrics) is created
# on-demand locally using create_daily_ttm_artifact().
#
# Input: s3://{bucket}/raw/{TICKER}/*.parquet
# Output:
#   s3://{bucket}/ttm-artifacts/{YYYY-MM-DD}/ttm_quarterly_artifact.parquet
#   s3://{bucket}/ttm-artifacts/{YYYY-MM-DD}/price_artifact.parquet
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
# LOAD ALL DATA
# ============================================================================

log_pipeline("Loading all raw data using Arrow datasets...")
load_start <- Sys.time()

all_data <- s3_load_all_raw_data(s3_bucket, aws_region)

load_duration <- as.numeric(difftime(Sys.time(), load_start, units = "secs"))
log_pipeline(sprintf("All data loaded in %.1f seconds", load_duration))

# Get unique tickers from the data
tickers <- unique(all_data$earnings$ticker)
n_tickers <- length(tickers)
log_pipeline(sprintf("Processing %d tickers", n_tickers))

# ============================================================================
# PROCESS TICKERS FOR QUARTERLY ARTIFACT (PARALLEL)
# ============================================================================

n_cores <- parallel::detectCores()
log_pipeline(sprintf("Processing tickers for quarterly TTM artifact using %d cores...", n_cores))
process_start <- Sys.time()

quarterly_results <- parallel::mclapply(tickers, function(ticker) {
  tryCatch({
    process_ticker_for_quarterly_artifact(
      ticker = ticker,
      all_data = all_data,
      start_date = start_date,
      threshold = threshold,
      lookback = lookback,
      lookahead = lookahead,
      end_window_size = end_window_size,
      end_threshold = end_threshold,
      min_obs = min_obs
    )
  }, error = function(e) {
    NULL
  })
}, mc.cores = n_cores)

# Combine quarterly results
log_pipeline("Combining quarterly results...")
quarterly_artifact <- dplyr::bind_rows(quarterly_results)

# Count successes/skips
success_count <- sum(sapply(quarterly_results, function(x) {
  !is.null(x) && nrow(x) > 0
}))
skip_count <- n_tickers - success_count

process_duration <- as.numeric(difftime(Sys.time(), process_start, units = "secs"))
log_pipeline(sprintf("Quarterly processing complete: %d success, %d skipped in %.1f seconds",
                     success_count, skip_count, process_duration))
log_pipeline(sprintf("Quarterly artifact: %d rows", nrow(quarterly_artifact)))

# ============================================================================
# PREPARE PRICE ARTIFACT
# ============================================================================

log_pipeline("Preparing price artifact...")

# Combine all price data and clean it
price_artifact <- all_data$price |>
  dplyr::filter(
    date >= start_date,
    !is.na(close) & close > 0
  ) |>
  dplyr::select(
    ticker,
    date,
    open,
    high,
    low,
    close,
    adjusted_close,
    volume,
    dividend_amount,
    split_coefficient
  ) |>
  dplyr::distinct() |>
  dplyr::arrange(ticker, date)

log_pipeline(sprintf("Price artifact: %d rows", nrow(price_artifact)))

# ============================================================================
# UPLOAD ARTIFACTS TO S3
# ============================================================================

artifact_date <- Sys.Date()
date_string <- format(artifact_date, "%Y-%m-%d")

# Upload quarterly artifact
log_pipeline("Uploading quarterly TTM artifact to S3...")
local_quarterly_path <- tempfile(fileext = ".parquet")
arrow::write_parquet(quarterly_artifact, local_quarterly_path)

quarterly_s3_key <- paste0("ttm-artifacts/", date_string, "/ttm_quarterly_artifact.parquet")
upload_artifact_to_s3(
  local_path = local_quarterly_path,
  bucket_name = s3_bucket,
  s3_key = quarterly_s3_key,
  region = aws_region
)
unlink(local_quarterly_path)
log_pipeline(sprintf("Uploaded: s3://%s/%s", s3_bucket, quarterly_s3_key))

# Upload price artifact
log_pipeline("Uploading price artifact to S3...")
local_price_path <- tempfile(fileext = ".parquet")
arrow::write_parquet(price_artifact, local_price_path)

price_s3_key <- paste0("ttm-artifacts/", date_string, "/price_artifact.parquet")
upload_artifact_to_s3(
  local_path = local_price_path,
  bucket_name = s3_bucket,
  s3_key = price_s3_key,
  region = aws_region
)
unlink(local_price_path)
log_pipeline(sprintf("Uploaded: s3://%s/%s", s3_bucket, price_s3_key))

# ============================================================================
# SUMMARY
# ============================================================================

phase_duration <- as.numeric(difftime(Sys.time(), phase_start_time, units = "secs"))
log_phase_end("PHASE 2: GENERATE TTM ARTIFACTS",
  total = n_tickers,
  successful = success_count,
  failed = 0,
  duration_seconds = phase_duration
)

log_pipeline(sprintf(
  "Artifacts created:\n  - Quarterly: %d rows (%.1f MB estimated)\n  - Price: %d rows (%.1f MB estimated)",
  nrow(quarterly_artifact),
  nrow(quarterly_artifact) * 500 / 1e6,  # rough estimate
  nrow(price_artifact),
  nrow(price_artifact) * 100 / 1e6  # rough estimate
))
