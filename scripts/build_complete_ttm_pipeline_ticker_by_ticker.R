# ============================================================================
# Complete TTM Per-Share Financial Artifact Pipeline (Ticker-by-Ticker)
# ============================================================================
# Refactored architecture that processes each ticker completely before moving
# to the next, eliminating memory bottlenecks from bulk processing.
#
# Key differences from bulk pipeline:
#   - Processes one ticker at a time (fetch → clean → calculate → append)
#   - Memory usage stays bounded (~5000 rows per iteration vs 10M rows)
#   - Final output identical to bulk pipeline (validated with all.equal())
#
# Output: cache/ttm_per_share_financial_artifact.parquet
# ============================================================================

devtools::load_all()

# ============================================================================
# CONFIGURATION
# ============================================================================

# Read configuration from environment variables with defaults
etf_symbol <- Sys.getenv("ETF_SYMBOL", "QQQ")
start_date_str <- Sys.getenv("START_DATE", "2004-12-31")
start_date <- as.Date(start_date_str)

# Anomaly detection parameters (matching bulk pipeline defaults)
threshold <- 4
lookback <- 5
lookahead <- 5
end_window_size <- 5
end_threshold <- 3
min_obs <- 10
delay_seconds <- 1

message("=" , paste(rep("=", 78), collapse = ""))
message("TTM PER-SHARE PIPELINE (TICKER-BY-TICKER)")
message("=" , paste(rep("=", 78), collapse = ""))
message("Configuration:")
message("  ETF Symbol: ", etf_symbol)
message("  Start Date: ", start_date)
message("  Anomaly Detection Threshold: ", threshold)
message("  API Delay: ", delay_seconds, " seconds")
message("")

# ============================================================================
# GET TICKER LIST
# ============================================================================

message("Fetching ticker list from ", etf_symbol, " holdings...")
tickers <- get_financial_statement_tickers(etf_symbol = etf_symbol)
n_tickers <- length(tickers)
message("  ✓ Found ", n_tickers, " tickers")
message("")

# ============================================================================
# PROCESS TICKERS ONE BY ONE
# ============================================================================

message("Processing tickers...")
message("")

# Initialize containers
final_artifact <- tibble::tibble()
failed_tickers <- character()
successful_tickers <- character()

# Process each ticker
for (i in seq_along(tickers)) {
  ticker <- tickers[i]
  
  message(sprintf("Processing %s (%d/%d)...", ticker, i, n_tickers))
  
  # Wrap in tryCatch to prevent one bad ticker from crashing pipeline
  ticker_result <- tryCatch(
    {
      process_single_ticker(
        ticker = ticker,
        start_date = start_date,
        threshold = threshold,
        lookback = lookback,
        lookahead = lookahead,
        end_window_size = end_window_size,
        end_threshold = end_threshold,
        min_obs = min_obs,
        delay_seconds = delay_seconds
      )
    },
    error = function(e) {
      message("  ✗ ", ticker, " failed: ", conditionMessage(e))
      return(NULL)
    }
  )
  
  # Handle result
  if (is.null(ticker_result)) {
    message("  ✗ ", ticker, " skipped (no data or processing failed)")
    failed_tickers <- c(failed_tickers, ticker)
  } else if (nrow(ticker_result) == 0) {
    message("  ✗ ", ticker, " skipped (empty result)")
    failed_tickers <- c(failed_tickers, ticker)
  } else {
    message("  ✓ ", ticker, " complete (", nrow(ticker_result), " rows)")
    final_artifact <- dplyr::bind_rows(final_artifact, ticker_result)
    successful_tickers <- c(successful_tickers, ticker)
  }
  
  # Memory cleanup every 100 tickers
  if (i %% 100 == 0) {
    rm(ticker_result)
    gc(verbose = FALSE)
    message("  [Memory cleanup performed]")
  }
  
  message("")
}

# Final cleanup
rm(ticker_result)
gc(verbose = FALSE)

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

message("=" , paste(rep("=", 78), collapse = ""))
message("PIPELINE SUMMARY")
message("=" , paste(rep("=", 78), collapse = ""))
message("Total tickers processed: ", n_tickers)
message("Successful: ", length(successful_tickers))
message("Failed/Skipped: ", length(failed_tickers))
message("")
message("Final artifact dimensions:")
message("  Rows: ", scales::comma(nrow(final_artifact)))
message("  Columns: ", ncol(final_artifact))
message("  Tickers: ", dplyr::n_distinct(final_artifact$ticker))
message("")

if (length(failed_tickers) > 0) {
  message("Failed/Skipped tickers:")
  for (ticker in failed_tickers) {
    message("  - ", ticker)
  }
  message("")
}

# ============================================================================
# SAVE OUTPUT
# ============================================================================

message("Saving artifact to cache/ttm_per_share_financial_artifact.parquet...")
arrow::write_parquet(final_artifact, "cache/ttm_per_share_financial_artifact.parquet")
message("  ✓ Artifact saved")
message("")

# ============================================================================
# COMPLETION
# ============================================================================

message("=" , paste(rep("=", 78), collapse = ""))
message("✓ PIPELINE COMPLETE")
message("=" , paste(rep("=", 78), collapse = ""))
