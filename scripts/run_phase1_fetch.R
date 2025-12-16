#!/usr/bin/env Rscript

# ============================================================================
# Phase 1: Fetch Raw Data to S3
# ============================================================================
# Fetches raw data from Alpha Vantage and stores per-ticker in S3.
# Uses smart refresh logic to minimize API calls:
#   - Price/splits: fetch on every scheduled run
#   - Quarterly: fetch only when near predicted earnings or stale
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

message("=", paste(rep("=", 78), collapse = ""))
message("PHASE 1: FETCH RAW DATA")
message("=", paste(rep("=", 78), collapse = ""))
message("Configuration:")
message("  ETF Symbol: ", etf_symbol)
message("  S3 Bucket: ", s3_bucket)
message("  AWS Region: ", aws_region)
message("  API Delay: ", delay_seconds, " seconds")
message("")

# ============================================================================
# GET API KEY
# ============================================================================

message("Retrieving API key...")
api_key <- get_api_key_from_parameter_store(
  parameter_name = "/avpipeline/alpha-vantage-api-key",
  region = aws_region
)
message("  API key retrieved successfully")
message("")

# ============================================================================
# LOAD REFRESH TRACKING
# ============================================================================

message("Loading refresh tracking from S3...")
tracking <- s3_read_refresh_tracking(s3_bucket, aws_region)
message("  Tracking loaded: ", nrow(tracking), " tickers")
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

successful_tickers <- character()
failed_tickers <- character()
reference_date <- Sys.Date()

for (i in seq_along(tickers)) {
  ticker <- tickers[i]

  tryCatch({
    message(sprintf("[%d/%d] %s", i, n_tickers, ticker))

    ticker_tracking <- get_ticker_tracking(tracking, ticker)

    fetch_requirements <- determine_fetch_requirements(
      ticker_tracking,
      reference_date
    )

    fetch_types <- names(fetch_requirements)[unlist(fetch_requirements)]
    if (length(fetch_types) == 0) {
      message("  Skipped (no fetch required)")
      successful_tickers <- c(successful_tickers, ticker)
      next
    }

    message("  Fetching: ", paste(fetch_types, collapse = ", "))

    results <- fetch_and_store_ticker_data(
      ticker = ticker,
      fetch_requirements = fetch_requirements,
      bucket_name = s3_bucket,
      api_key = api_key,
      region = aws_region,
      delay_seconds = delay_seconds
    )

    any_error <- any(sapply(results, function(r) !isTRUE(r$success)))

    if (any_error) {
      error_msgs <- sapply(results, function(r) r$error)
      error_msgs <- error_msgs[!sapply(error_msgs, is.null)]
      tracking <- update_tracking_after_error(
        tracking,
        ticker,
        paste(error_msgs, collapse = "; ")
      )
      failed_tickers <- c(failed_tickers, ticker)
      message("  Error: ", paste(error_msgs, collapse = "; "))
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
      successful_tickers <- c(successful_tickers, ticker)
      message("  Success")
    }

    if (i %% 10 == 0) {
      gc(verbose = FALSE)
    }

  }, error = function(e) {
    tracking <<- update_tracking_after_error(tracking, ticker, conditionMessage(e))
    failed_tickers <<- c(failed_tickers, ticker)
    message("  Error: ", conditionMessage(e))
  })
}

# ============================================================================
# SAVE TRACKING
# ============================================================================

message("")
message("Saving refresh tracking to S3...")
s3_write_refresh_tracking(tracking, s3_bucket, aws_region)
message("  Tracking saved")

# ============================================================================
# SUMMARY
# ============================================================================

message("")
message("=", paste(rep("=", 78), collapse = ""))
message("PHASE 1 COMPLETE")
message("=", paste(rep("=", 78), collapse = ""))
message("  Successful: ", length(successful_tickers))
message("  Failed: ", length(failed_tickers))
if (length(failed_tickers) > 0) {
  message("  Failed tickers: ", paste(failed_tickers, collapse = ", "))
}
message("")
