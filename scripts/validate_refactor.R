#!/usr/bin/env Rscript

# ============================================================================
# Validation Script: Compare Old vs New Architecture Output
# ============================================================================
# Loads data ONLY for test tickers (not all 2000+), then compares outputs.
# ============================================================================

devtools::load_all()

# ============================================================================
# CONFIGURATION
# ============================================================================

test_tickers <- c("AAPL", "MSFT", "GOOGL")
start_date <- as.Date("2010-01-01")
s3_bucket <- Sys.getenv("S3_BUCKET", "avpipeline-artifacts-prod")
aws_region <- Sys.getenv("AWS_REGION", "us-east-1")

threshold <- 4
lookback <- 5
lookahead <- 5
end_window_size <- 5
end_threshold <- 3
min_obs <- 10

cat("=== VALIDATION: Comparing Old vs New Architecture ===\n")
cat(sprintf("Test tickers: %s\n", paste(test_tickers, collapse = ", ")))
cat(sprintf("Start date: %s\n\n", start_date))

# ============================================================================
# LOAD DATA ONLY FOR TEST TICKERS (fast!)
# ============================================================================

cat("Loading data for test tickers only...\n")

data_types <- c("balance_sheet", "income_statement", "cash_flow",
                "earnings", "price", "splits", "overview")

all_data <- list()
for (dt in data_types) {
  cat(sprintf("  Loading %s...\n", dt))
  dfs <- lapply(test_tickers, function(ticker) {
    uri <- sprintf("s3://%s/raw/%s/%s.parquet?region=%s",
                   s3_bucket, ticker, dt, aws_region)
    tryCatch(arrow::read_parquet(uri), error = function(e) NULL)
  })
  all_data[[dt]] <- dplyr::bind_rows(dfs[!sapply(dfs, is.null)])
}
cat("Data loaded.\n\n")

# ============================================================================
# PROCESS WITH OLD METHOD
# ============================================================================

cat("Processing with OLD method (process_ticker_from_memory)...\n")
old_results <- lapply(test_tickers, function(ticker) {
  cat(sprintf("  %s...\n", ticker))
  tryCatch({
    process_ticker_from_memory(
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
    cat(sprintf("    Error: %s\n", e$message))
    NULL
  })
})
old_combined <- dplyr::bind_rows(old_results)
cat(sprintf("OLD: %d rows\n\n", nrow(old_combined)))

# ============================================================================
# PROCESS WITH NEW METHOD
# ============================================================================

cat("Processing with NEW method...\n")

# Step 1: Quarterly artifact
cat("  Creating quarterly artifact...\n")
quarterly_results <- lapply(test_tickers, function(ticker) {
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
  }, error = function(e) NULL)
})
quarterly_df <- dplyr::bind_rows(quarterly_results)

# Step 2: Price artifact (don't filter by start_date to match old behavior)
price_df <- all_data$price |>
  dplyr::filter(!is.na(close) & close > 0) |>
  dplyr::select(ticker, date, open, high, low, close, adjusted_close,
                volume, dividend_amount, split_coefficient) |>
  dplyr::distinct() |>
  dplyr::arrange(ticker, date)

# Step 3: Create daily artifact
cat("  Creating daily artifact...\n")
new_combined <- create_daily_ttm_artifact(
  quarterly_df = quarterly_df,
  price_df = price_df,
  start_date = start_date
)
cat(sprintf("NEW: %d rows\n\n", nrow(new_combined)))

# ============================================================================
# COMPARE
# ============================================================================

cat("=== COMPARISON ===\n")
cat(sprintf("Rows: OLD=%d, NEW=%d\n", nrow(old_combined), nrow(new_combined)))

# Compare columns
old_cols <- sort(names(old_combined))
new_cols <- sort(names(new_combined))
common_cols <- intersect(old_cols, new_cols)

missing <- setdiff(old_cols, new_cols)
extra <- setdiff(new_cols, old_cols)
if (length(missing) > 0) cat(sprintf("Missing in NEW: %s\n", paste(missing, collapse=", ")))
if (length(extra) > 0) cat(sprintf("Extra in NEW: %s\n", paste(extra, collapse=", ")))

# Sort both for comparison
old_sorted <- old_combined |> dplyr::arrange(ticker, date)
new_sorted <- new_combined |> dplyr::arrange(ticker, date)

# Compare numeric columns
differences <- list()
for (col in common_cols) {
  if (col %in% c("ticker", "date")) next

  old_v <- old_sorted[[col]]
  new_v <- new_sorted[[col]]

  if (is.numeric(old_v) && is.numeric(new_v)) {
    diff_count <- sum(abs(old_v - new_v) > 1e-6, na.rm = TRUE) +
                  sum(is.na(old_v) != is.na(new_v))
    if (diff_count > 0) differences[[col]] <- diff_count
  }
}

if (length(differences) == 0) {
  cat("\n*** SUCCESS: All numeric columns match! ***\n")
} else {
  cat("\nDifferences found:\n")
  for (col in names(differences)) {
    cat(sprintf("  %s: %d rows differ\n", col, differences[[col]]))
  }
}

cat("\n=== DONE ===\n")
