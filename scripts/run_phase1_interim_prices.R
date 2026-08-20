#!/usr/bin/env Rscript

# ============================================================================
# Phase 1 (Daily): Fetch Interim Prices via Realtime Bulk Quotes
# ============================================================================
# Fast daily price path. Fetches current-day bulk quotes for the full ticker
# universe in ~N/100 API calls and accumulates them into the consolidated
# interim store. Does NOT touch the per-ticker authoritative price files —
# the weekly TIME_SERIES_DAILY_ADJUSTED run remains the sole source of truth
# and supersedes interim bars on its next pass.
#
# Output: s3://{bucket}/interim/interim_quotes.parquet
# Sourced by run_phase1_aws.R when FETCH_MODE=bulk_interim.
# ============================================================================

devtools::load_all()

etf_symbol <- Sys.getenv("ETF_SYMBOL", "QQQ")
aws_region <- Sys.getenv("AWS_REGION", "us-east-1")
s3_bucket <- Sys.getenv("S3_BUCKET")

if (s3_bucket == "") {
  stop("S3_BUCKET environment variable is required")
}

phase_start_time <- Sys.time()
log_phase_start(
  "PHASE 1 (DAILY): INTERIM PRICES",
  sprintf("ETF: %s | Bucket: %s | Mode: bulk_interim", etf_symbol, s3_bucket)
)

api_key <- get_api_key_from_parameter_store(
  parameter_name = "/avpipeline/alpha-vantage-api-key",
  region = aws_region
)
Sys.setenv(ALPHA_VANTAGE_API_KEY = api_key)

# Quote the same universe Phase 1 fetches: ETF holdings plus existing S3 tickers
etf_tickers <- get_financial_statement_tickers(etf_symbol = etf_symbol)
s3_tickers <- s3_list_existing_tickers(s3_bucket, aws_region)
all_tickers <- unique(c(etf_tickers, s3_tickers))

interim <- fetch_and_store_interim_quotes(
  symbols = all_tickers,
  bucket_name = s3_bucket,
  api_key = api_key,
  region = aws_region
)

duration <- round(
  as.numeric(difftime(Sys.time(), phase_start_time, units = "mins")),
  2
)
message(sprintf(
  "Interim quotes stored: %d rows across %d tickers (%d trading days) | %.2f min",
  nrow(interim),
  length(unique(interim$ticker)),
  length(unique(interim$date)),
  duration
))

# Contract for run_phase1_aws.R's notification. Without this the daily run's
# entire reason for existing — the bulk-quote price leg — is invisible in the
# email, and a run that quoted zero tickers still reports unqualified success.
interim_summary <- list(
  rows = nrow(interim),
  tickers = length(unique(interim$ticker)),
  trading_days = length(unique(interim$date))
)
