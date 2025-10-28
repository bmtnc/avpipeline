# ============================================================================
# Test Script: Ticker-by-Ticker Pipeline (Small Subset)
# ============================================================================
# Tests the new ticker-by-ticker pipeline with 3-5 tickers to validate logic
# before running full QQQ validation.
# ============================================================================

devtools::load_all()

# ============================================================================
# CONFIGURATION
# ============================================================================

start_date <- as.Date("2004-12-31")

# Test with a small set of well-known tickers
test_tickers <- c("AAPL", "MSFT", "GOOGL")

message("=" , paste(rep("=", 78), collapse = ""))
message("TICKER-BY-TICKER PIPELINE TEST (3 TICKERS)")
message("=" , paste(rep("=", 78), collapse = ""))
message("Test Tickers: ", paste(test_tickers, collapse = ", "))
message("Start Date: ", start_date)
message("")

# ============================================================================
# PROCESS TEST TICKERS
# ============================================================================

final_artifact <- tibble::tibble()

for (i in seq_along(test_tickers)) {
  ticker <- test_tickers[i]
  
  message(sprintf("Processing %s (%d/%d)...", ticker, i, length(test_tickers)))
  
  ticker_result <- tryCatch(
    {
      process_single_ticker(
        ticker = ticker,
        start_date = start_date,
        threshold = 4,
        lookback = 5,
        lookahead = 5,
        end_window_size = 5,
        end_threshold = 3,
        min_obs = 10,
        delay_seconds = 1
      )
    },
    error = function(e) {
      message("  ✗ ERROR: ", conditionMessage(e))
      return(NULL)
    }
  )
  
  if (!is.null(ticker_result) && nrow(ticker_result) > 0) {
    message("  ✓ Success: ", nrow(ticker_result), " rows")
    final_artifact <- dplyr::bind_rows(final_artifact, ticker_result)
  } else {
    message("  ✗ Failed or no data")
  }
  
  message("")
}

# ============================================================================
# RESULTS SUMMARY
# ============================================================================

message("=" , paste(rep("=", 78), collapse = ""))
message("TEST RESULTS")
message("=" , paste(rep("=", 78), collapse = ""))
message("Final artifact dimensions:")
message("  Rows: ", scales::comma(nrow(final_artifact)))
message("  Columns: ", ncol(final_artifact))
message("  Tickers: ", dplyr::n_distinct(final_artifact$ticker))
message("")

if (nrow(final_artifact) > 0) {
  message("Sample data (first 5 rows):")
  print(head(final_artifact %>% dplyr::select(ticker, date, market_cap, totalRevenue_ttm_per_share), 5))
  message("")
  
  message("Date range by ticker:")
  date_summary <- final_artifact %>%
    dplyr::group_by(ticker) %>%
    dplyr::summarise(
      min_date = min(date),
      max_date = max(date),
      n_rows = dplyr::n(),
      .groups = "drop"
    )
  print(date_summary)
  message("")
  
  # Save test output
  message("Saving test output to cache/test_ticker_by_ticker_small.parquet...")
  arrow::write_parquet(final_artifact, "cache/test_ticker_by_ticker_small.parquet")
  message("  ✓ Saved")
  message("")
}

message("=" , paste(rep("=", 78), collapse = ""))
message("✓ TEST COMPLETE")
message("=" , paste(rep("=", 78), collapse = ""))
