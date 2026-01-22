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
fetch_mode <- Sys.getenv("FETCH_MODE", "full")

if (s3_bucket == "") {
  stop("S3_BUCKET environment variable is required")
}

if (!fetch_mode %in% c("full", "price_only", "quarterly_only")) {
  stop("FETCH_MODE must be 'full', 'price_only', or 'quarterly_only'")
}

phase_start_time <- Sys.time()
log_phase_start("PHASE 1: FETCH RAW DATA",
  sprintf("ETF: %s | Bucket: %s | Mode: %s", etf_symbol, s3_bucket, fetch_mode)
)

# ============================================================================
# SETUP
# ============================================================================

api_key <- get_api_key_from_parameter_store(
  parameter_name = "/avpipeline/alpha-vantage-api-key",
  region = aws_region
)
Sys.setenv(ALPHA_VANTAGE_API_KEY = api_key)

tracking <- s3_read_refresh_tracking(s3_bucket, aws_region)

# Get tickers from both ETF holdings AND existing S3 data
etf_tickers <- get_financial_statement_tickers(etf_symbol = etf_symbol)
s3_tickers <- s3_list_existing_tickers(s3_bucket, aws_region)
all_tickers <- unique(c(etf_tickers, s3_tickers))

# Load checkpoint and filter to unprocessed tickers
checkpoint <- s3_read_checkpoint(s3_bucket, "phase1", aws_region)
already_processed <- checkpoint$processed_tickers %||% character(0)
tickers <- setdiff(all_tickers, already_processed)
n_tickers <- length(tickers)
n_total <- length(all_tickers)

log_pipeline(sprintf("Total tickers: %d (%d ETF + %d additional from S3)",
        n_total, length(etf_tickers), length(setdiff(s3_tickers, etf_tickers))))

if (length(already_processed) > 0) {
  log_pipeline(sprintf("Resuming from checkpoint: %d already processed, %d remaining",
          length(already_processed), n_tickers))
}

# ============================================================================
# PROCESS TICKERS
# ============================================================================

pipeline_log <- create_pipeline_log()
reference_date <- Sys.Date()
success_count <- 0
error_count <- 0
skip_count <- 0
failed_tickers <- character(0)
loop_start_time <- Sys.time()

for (i in seq_along(tickers)) {
  ticker <- tickers[i]
  ticker_start <- Sys.time()

  tryCatch({
    ticker_tracking <- get_ticker_tracking(ticker, tracking)

    fetch_requirements <- determine_fetch_requirements(
      ticker_tracking,
      reference_date,
      fetch_mode = fetch_mode
    )

    fetch_types <- names(fetch_requirements)[unlist(fetch_requirements)]

    if (length(fetch_types) == 0) {
      skip_count <- skip_count + 1
      checkpoint <- update_checkpoint(checkpoint, ticker, success = TRUE)
      pipeline_log <- add_log_entry(
        pipeline_log, ticker, "fetch", "all", "skipped",
        duration_seconds = as.numeric(difftime(Sys.time(), ticker_start, units = "secs"))
      )
      next
    }

    results <- fetch_and_store_ticker_data(
      ticker = ticker,
      fetch_requirements = fetch_requirements,
      ticker_tracking = ticker_tracking,
      bucket_name = s3_bucket,
      api_key = api_key,
      region = aws_region,
      delay_seconds = delay_seconds
    )

    any_error <- any(sapply(results, function(r) !isTRUE(r$success)))
    duration <- as.numeric(difftime(Sys.time(), ticker_start, units = "secs"))

    if (any_error) {
      error_count <- error_count + 1
      failed_tickers <- c(failed_tickers, ticker)
      error_msgs <- sapply(results, function(r) r$error)
      error_msgs <- error_msgs[!sapply(error_msgs, is.null)]
      tracking <- update_tracking_after_error(
        tracking, ticker, paste(error_msgs, collapse = "; ")
      )
      checkpoint <- update_checkpoint(checkpoint, ticker, success = FALSE)
      pipeline_log <- add_log_entry(
        pipeline_log, ticker, "fetch", paste(fetch_types, collapse = ","),
        "error", error_message = paste(error_msgs, collapse = "; "),
        duration_seconds = duration
      )
    } else {
      success_count <- success_count + 1
      if (isTRUE(fetch_requirements$price)) {
        price_data <- results$price$data
        price_last_date <- if (!is.null(price_data) && nrow(price_data) > 0) {
          max(price_data$date, na.rm = TRUE)
        } else {
          NULL
        }
        price_has_full_history <- results$price$outputsize_used == "full"

        tracking <- update_tracking_after_fetch(
          tracking, ticker, "price",
          price_last_date = price_last_date,
          price_has_full_history = price_has_full_history
        )
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
      total_rows <- sum(sapply(results, function(r) {
        if (!is.null(r$data)) nrow(r$data) else 0L
      }))

      checkpoint <- update_checkpoint(checkpoint, ticker, success = TRUE)
      pipeline_log <- add_log_entry(
        pipeline_log, ticker, "fetch", paste(fetch_types, collapse = ","),
        "success", rows = total_rows, duration_seconds = duration
      )
    }

    # Log progress and save checkpoint every 25 tickers
    if (i %% 25 == 0) {
      elapsed <- as.numeric(difftime(Sys.time(), loop_start_time, units = "secs"))
      log_progress_summary(i, n_tickers, success_count, error_count,
                           elapsed_seconds = elapsed)
      s3_write_checkpoint(checkpoint, s3_bucket, "phase1", aws_region)
      gc(verbose = FALSE)
    }

  }, error = function(e) {
    error_count <<- error_count + 1
    failed_tickers <<- c(failed_tickers, ticker)
    tracking <<- update_tracking_after_error(tracking, ticker, conditionMessage(e))
    checkpoint <<- update_checkpoint(checkpoint, ticker, success = FALSE)
    pipeline_log <<- add_log_entry(
      pipeline_log, ticker, "fetch", "unknown", "error",
      error_message = conditionMessage(e),
      duration_seconds = as.numeric(difftime(Sys.time(), ticker_start, units = "secs"))
    )
  })
}

# ============================================================================
# SAVE TRACKING & LOG
# ============================================================================

s3_write_refresh_tracking(tracking, s3_bucket, aws_region)
log_pipeline("Tracking saved to S3")

# Clear checkpoint on successful completion
s3_clear_checkpoint(s3_bucket, "phase1", aws_region)
log_pipeline("Checkpoint cleared (phase complete)")

# ============================================================================
# SUMMARY
# ============================================================================

phase_duration <- as.numeric(difftime(Sys.time(), phase_start_time, units = "secs"))
log_phase_end("PHASE 1: FETCH RAW DATA",
  total = n_tickers,
  successful = success_count + skip_count,
  failed = error_count,
  duration_seconds = phase_duration
)
log_failed_tickers(failed_tickers)

# Return log for use by run_pipeline_aws.R
phase1_log <- pipeline_log
