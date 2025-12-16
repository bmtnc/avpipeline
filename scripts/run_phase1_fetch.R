#!/usr/bin/env Rscript

# ============================================================================
# Phase 1: Fetch Raw Data to S3
# ============================================================================
# Fetches raw data from Alpha Vantage and stores per-ticker in S3.
# Uses smart refresh logic to minimize API calls.
#
# Output: s3://{bucket}/raw/{TICKER}/*.parquet
# ============================================================================

devtools::load_all()

# ============================================================================
# CONFIGURATION
# ============================================================================

etf_symbol <- Sys.getenv("ETF_SYMBOL", "QQQ")
aws_region <- Sys.getenv("AWS_REGION", "us-east-1")
s3_bucket <- Sys.getenv("S3_BUCKET")
delay_seconds <- as.numeric(Sys.getenv("API_DELAY_SECONDS", "1"))

if (s3_bucket == "") {
  stop("S3_BUCKET environment variable is required")
}

message("=== PHASE 1: FETCH RAW DATA ===")
message("ETF: ", etf_symbol, " | Bucket: ", s3_bucket)

# ============================================================================
# SETUP
# ============================================================================

api_key <- get_api_key_from_parameter_store(
  parameter_name = "/avpipeline/alpha-vantage-api-key",
  region = aws_region
)
Sys.setenv(ALPHA_VANTAGE_API_KEY = api_key)

tracking <- s3_read_refresh_tracking(s3_bucket, aws_region)
tickers <- get_financial_statement_tickers(etf_symbol = etf_symbol)
n_tickers <- length(tickers)

message("Tickers: ", n_tickers, " | Tracking: ", nrow(tracking), " existing")
message("")

# ============================================================================
# PROCESS TICKERS
# ============================================================================

pipeline_log <- create_pipeline_log()
reference_date <- Sys.Date()

for (i in seq_along(tickers)) {
  ticker <- tickers[i]
  start_time <- Sys.time()

  print_progress(i, n_tickers, "Fetch", ticker)

  tryCatch({
    ticker_tracking <- get_ticker_tracking(ticker, tracking)

    fetch_requirements <- determine_fetch_requirements(
      ticker_tracking,
      reference_date
    )

    fetch_types <- names(fetch_requirements)[unlist(fetch_requirements)]

    if (length(fetch_types) == 0) {
      pipeline_log <- add_log_entry(
        pipeline_log, ticker, "fetch", "all", "skipped",
        duration_seconds = as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      )
      next
    }

    results <- suppressMessages(fetch_and_store_ticker_data(
      ticker = ticker,
      fetch_requirements = fetch_requirements,
      bucket_name = s3_bucket,
      api_key = api_key,
      region = aws_region,
      delay_seconds = delay_seconds
    ))

    any_error <- any(sapply(results, function(r) !isTRUE(r$success)))
    duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

    if (any_error) {
      error_msgs <- sapply(results, function(r) r$error)
      error_msgs <- error_msgs[!sapply(error_msgs, is.null)]
      tracking <- update_tracking_after_error(
        tracking, ticker, paste(error_msgs, collapse = "; ")
      )
      pipeline_log <- add_log_entry(
        pipeline_log, ticker, "fetch", paste(fetch_types, collapse = ","),
        "error", error_message = paste(error_msgs, collapse = "; "),
        duration_seconds = duration
      )
    } else {
      if (isTRUE(fetch_requirements$price)) {
        tracking <- update_tracking_after_fetch(tracking, ticker, "price")
      }
      if (isTRUE(fetch_requirements$splits)) {
        tracking <- update_tracking_after_fetch(tracking, ticker, "splits")
      }
      if (isTRUE(fetch_requirements$quarterly)) {
        earnings_data <- results$earnings$data
        if (!is.null(earnings_data) && nrow(earnings_data) > 0) {
          tracking <- update_earnings_prediction(tracking, ticker, earnings_data)
        }
        tracking <- update_tracking_after_fetch(
          tracking, ticker, "quarterly",
          fiscal_date_ending = if (!is.null(earnings_data) && nrow(earnings_data) > 0)
            max(earnings_data$fiscalDateEnding, na.rm = TRUE) else NULL,
          reported_date = if (!is.null(earnings_data) && nrow(earnings_data) > 0)
            max(earnings_data$reportedDate, na.rm = TRUE) else NULL
        )
      }
      if (isTRUE(fetch_requirements$overview)) {
        tracking <- update_tracking_after_fetch(tracking, ticker, "overview")
      }

      total_rows <- sum(sapply(results, function(r) {
        if (!is.null(r$data)) nrow(r$data) else 0L
      }))

      pipeline_log <- add_log_entry(
        pipeline_log, ticker, "fetch", paste(fetch_types, collapse = ","),
        "success", rows = total_rows, duration_seconds = duration
      )
    }

    if (i %% 10 == 0) gc(verbose = FALSE)

  }, error = function(e) {
    tracking <<- update_tracking_after_error(tracking, ticker, conditionMessage(e))
    pipeline_log <<- add_log_entry(
      pipeline_log, ticker, "fetch", "unknown", "error",
      error_message = conditionMessage(e),
      duration_seconds = as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    )
  })
}

# ============================================================================
# SAVE TRACKING & LOG
# ============================================================================

message("")
s3_write_refresh_tracking(tracking, s3_bucket, aws_region)
message("Tracking saved")

# ============================================================================
# SUMMARY
# ============================================================================

message("")
message("=== PHASE 1 COMPLETE ===")
print_log_summary(pipeline_log, "fetch")

# Return log for use by run_pipeline_aws.R
phase1_log <- pipeline_log
