#!/usr/bin/env Rscript

# ============================================================================
# Phase 2: Generate TTM Artifacts from S3 Raw Data
# ============================================================================
# Reads raw data from S3 and generates the TTM per-share financial artifact.
# Reuses existing processing functions unchanged.
#
# Input: s3://{bucket}/raw/{TICKER}/*.parquet
# Output: s3://{bucket}/ttm-artifacts/{YYYY-MM-DD}/ttm_per_share_financial_artifact.parquet
# ============================================================================

devtools::load_all()

# ============================================================================
# CONFIGURATION
# ============================================================================

etf_symbol <- Sys.getenv("ETF_SYMBOL", "QQQ")
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

message("=", paste(rep("=", 78), collapse = ""))
message("PHASE 2: GENERATE TTM ARTIFACTS")
message("=", paste(rep("=", 78), collapse = ""))
message("Configuration:")
message("  ETF Symbol: ", etf_symbol)
message("  Start Date: ", start_date)
message("  S3 Bucket: ", s3_bucket)
message("  AWS Region: ", aws_region)
message("")

# ============================================================================
# GET TICKER LIST
# ============================================================================

message("Fetching ticker list from ", etf_symbol, " holdings...")
tickers <- get_financial_statement_tickers(etf_symbol = etf_symbol)
n_tickers <- length(tickers)
message("  Found ", n_tickers, " tickers")
message("")

# ============================================================================
# PROCESS TICKERS
# ============================================================================

message("Processing tickers...")
message("")

final_artifact <- tibble::tibble()
successful_tickers <- character()
failed_tickers <- character()

for (i in seq_along(tickers)) {
  ticker <- tickers[i]

  tryCatch({
    message(sprintf("[%d/%d] %s", i, n_tickers, ticker))

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

    if (!is.null(result) && nrow(result) > 0) {
      final_artifact <- dplyr::bind_rows(final_artifact, result)
      successful_tickers <- c(successful_tickers, ticker)
      message("  Success (", nrow(result), " rows)")
    } else {
      failed_tickers <- c(failed_tickers, ticker)
      message("  Skipped (no data)")
    }

    if (i %% 10 == 0) {
      gc(verbose = FALSE)
    }
    if (i %% 50 == 0) {
      gc(full = TRUE, verbose = FALSE)
    }

  }, error = function(e) {
    failed_tickers <<- c(failed_tickers, ticker)
    message("  Error: ", conditionMessage(e))
  })
}

# ============================================================================
# UPLOAD ARTIFACT TO S3
# ============================================================================

message("")
message("Uploading TTM artifact to S3...")

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

message("  Artifact uploaded: s3://", s3_bucket, "/", s3_key)

# ============================================================================
# SUMMARY
# ============================================================================

message("")
message("=", paste(rep("=", 78), collapse = ""))
message("PHASE 2 COMPLETE")
message("=", paste(rep("=", 78), collapse = ""))
message("  Total rows: ", nrow(final_artifact))
message("  Successful: ", length(successful_tickers))
message("  Failed: ", length(failed_tickers))
if (length(failed_tickers) > 0) {
  message("  Failed tickers: ", paste(failed_tickers, collapse = ", "))
}
message("")
