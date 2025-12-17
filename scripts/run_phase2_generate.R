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

message("=== PHASE 2: GENERATE TTM ARTIFACTS ===")
message("ETF: ", etf_symbol, " | Start: ", start_date)

# ============================================================================
# SETUP
# ============================================================================

api_key <- get_api_key_from_parameter_store(
  parameter_name = "/avpipeline/alpha-vantage-api-key",
  region = aws_region
)
Sys.setenv(ALPHA_VANTAGE_API_KEY = api_key)

tickers <- get_financial_statement_tickers(etf_symbol = etf_symbol)
n_tickers <- length(tickers)

message("Tickers: ", n_tickers)
message("")

# ============================================================================
# PROCESS TICKERS
# ============================================================================

final_artifact <- tibble::tibble()
pipeline_log <- if (exists("phase1_log")) phase1_log else create_pipeline_log()

for (i in seq_along(tickers)) {
  ticker <- tickers[i]
  ticker_start <- Sys.time()

  print_progress(i, n_tickers, "Generate", ticker)

  tryCatch({
    result <- suppressMessages(process_ticker_from_s3(
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
    ))

    duration <- as.numeric(difftime(Sys.time(), ticker_start, units = "secs"))

    if (!is.null(result) && nrow(result) > 0) {
      final_artifact <- dplyr::bind_rows(final_artifact, result)
      pipeline_log <- add_log_entry(
        pipeline_log, ticker, "generate", "ttm", "success",
        rows = nrow(result), duration_seconds = duration
      )
    } else {
      pipeline_log <- add_log_entry(
        pipeline_log, ticker, "generate", "ttm", "skipped",
        error_message = "No data returned", duration_seconds = duration
      )
    }

    if (i %% 10 == 0) gc(verbose = FALSE)
    if (i %% 50 == 0) gc(full = TRUE, verbose = FALSE)

  }, error = function(e) {
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

message("  Artifact: s3://", s3_bucket, "/", s3_key, " (", nrow(final_artifact), " rows)")

# ============================================================================
# SUMMARY
# ============================================================================

message("")
message("=== PHASE 2 COMPLETE ===")
print_log_summary(pipeline_log, "generate")

# Return log for use by run_pipeline_aws.R
phase2_log <- pipeline_log
