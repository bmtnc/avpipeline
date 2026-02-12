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
# Supports two modes via PHASE2_MODE environment variable:
#   - "incremental" (default): Only reprocess tickers updated in Phase 1,
#     merge with unchanged rows from previous artifact
#   - "full": Reprocess all tickers from scratch
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
phase2_mode <- Sys.getenv("PHASE2_MODE", "incremental")

if (s3_bucket == "") {
  stop("S3_BUCKET environment variable is required")
}
if (!phase2_mode %in% c("incremental", "full")) {
  stop("PHASE2_MODE must be 'incremental' or 'full'")
}

threshold <- 4
lookback <- 5
lookahead <- 5
end_window_size <- 5
end_threshold <- 3
min_obs <- 10

phase_start_time <- Sys.time()
log_phase_start("PHASE 2: GENERATE TTM ARTIFACTS",
  sprintf("Start date: %s | Bucket: %s | Mode: %s", start_date, s3_bucket, phase2_mode)
)

# ============================================================================
# LOAD DATA AND DETERMINE REPROCESS SET
# ============================================================================

previous_artifact <- NULL
reprocess_info <- NULL

if (phase2_mode == "incremental") {
  log_pipeline("Incremental mode: determining reprocess set...")

  # Read manifest from Phase 1
  manifest <- s3_read_phase1_manifest(s3_bucket, aws_region)
  if (!is.null(manifest)) {
    log_pipeline(sprintf("Manifest loaded: %d tickers updated in Phase 1", nrow(manifest)))
  } else {
    log_pipeline("No manifest found, will fall back to full reprocess")
  }

  # Get all tickers currently in S3
  s3_tickers <- s3_list_existing_tickers(s3_bucket, aws_region)
  log_pipeline(sprintf("S3 raw data: %d tickers", length(s3_tickers)))

  # Load previous quarterly artifact
  previous_artifact <- tryCatch({
    artifact <- load_quarterly_artifact(s3_bucket, region = aws_region)
    log_pipeline(sprintf("Previous artifact loaded: %d rows, %d tickers",
                         nrow(artifact), length(unique(artifact$ticker))))
    artifact
  }, error = function(e) {
    log_pipeline(sprintf("No previous artifact found: %s", e$message))
    NULL
  })

  previous_artifact_tickers <- if (!is.null(previous_artifact)) {
    unique(previous_artifact$ticker)
  } else {
    character(0)
  }

  # Determine what to reprocess
  reprocess_info <- determine_phase2_reprocess_set(
    manifest = manifest,
    previous_artifact_tickers = previous_artifact_tickers,
    s3_tickers = s3_tickers
  )

  log_pipeline(sprintf(
    "Reprocess set (%s): %d to reprocess | %d unchanged | %d dropped",
    reprocess_info$reason,
    length(reprocess_info$reprocess_tickers),
    length(reprocess_info$unchanged_tickers),
    length(reprocess_info$dropped_tickers)
  ))

  if (length(reprocess_info$dropped_tickers) > 0) {
    log_pipeline(sprintf("Dropped tickers (no longer in S3): %s",
      paste(head(reprocess_info$dropped_tickers, 20), collapse = ", ")))
  }
}

# ============================================================================
# SYNC AND LOAD RAW DATA
# ============================================================================

log_pipeline("Syncing raw data from S3...")
load_start <- Sys.time()

all_data <- s3_load_all_raw_data(s3_bucket, aws_region)

load_duration <- as.numeric(difftime(Sys.time(), load_start, units = "secs"))
log_pipeline(sprintf("All data loaded in %.1f seconds", load_duration))

# Save price data before splitting (needed intact for price artifact later)
price_data <- all_data$price

# Determine tickers to process
if (phase2_mode == "incremental" && reprocess_info$reason == "incremental") {
  tickers <- reprocess_info$reprocess_tickers
  # Filter all_data to only reprocess tickers (reduce memory for pre-split)
  for (dt in names(all_data)) {
    if (dt == "price") next
    if (nrow(all_data[[dt]]) > 0 && "ticker" %in% names(all_data[[dt]])) {
      all_data[[dt]] <- dplyr::filter(all_data[[dt]], ticker %in% tickers)
    }
  }
} else {
  tickers <- unique(all_data$earnings$ticker)
}

# Pre-split data by ticker for O(1) lookups in parallel workers
log_pipeline("Pre-splitting data by ticker...")
split_start <- Sys.time()

for (dt in names(all_data)) {
  if (dt == "price") next
  if (nrow(all_data[[dt]]) > 0 && "ticker" %in% names(all_data[[dt]])) {
    all_data[[dt]] <- split(all_data[[dt]], all_data[[dt]]$ticker)
  }
}

split_duration <- as.numeric(difftime(Sys.time(), split_start, units = "secs"))
log_pipeline(sprintf("Data pre-split by ticker in %.1f seconds", split_duration))

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

# Combine quarterly results from reprocessed tickers
log_pipeline("Combining quarterly results...")
reprocessed_artifact <- dplyr::bind_rows(quarterly_results)

# Count successes/skips
success_count <- sum(sapply(quarterly_results, function(x) {
  !is.null(x) && nrow(x) > 0
}))
skip_count <- n_tickers - success_count

process_duration <- as.numeric(difftime(Sys.time(), process_start, units = "secs"))
log_pipeline(sprintf("Quarterly processing complete: %d success, %d skipped in %.1f seconds",
                     success_count, skip_count, process_duration))

# ============================================================================
# MERGE WITH PREVIOUS ARTIFACT (INCREMENTAL MODE)
# ============================================================================

if (phase2_mode == "incremental" && !is.null(previous_artifact) &&
    reprocess_info$reason == "incremental" &&
    length(reprocess_info$unchanged_tickers) > 0) {

  log_pipeline(sprintf("Merging %d unchanged tickers from previous artifact...",
                       length(reprocess_info$unchanged_tickers)))

  unchanged_rows <- dplyr::filter(
    previous_artifact,
    ticker %in% reprocess_info$unchanged_tickers
  )

  quarterly_artifact <- dplyr::bind_rows(unchanged_rows, reprocessed_artifact)

  log_pipeline(sprintf("Merged: %d unchanged rows + %d reprocessed rows = %d total",
                       nrow(unchanged_rows), nrow(reprocessed_artifact),
                       nrow(quarterly_artifact)))
} else {
  quarterly_artifact <- reprocessed_artifact
}

log_pipeline(sprintf("Quarterly artifact: %d rows", nrow(quarterly_artifact)))

# ============================================================================
# PREPARE PRICE ARTIFACT
# ============================================================================

log_pipeline("Preparing price artifact...")

# Combine all price data and clean it
price_artifact <- price_data |>
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
