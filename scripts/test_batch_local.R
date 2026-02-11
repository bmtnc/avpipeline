#!/usr/bin/env Rscript

# ============================================================================
# Local Smoke Test: Phase 1 Batch Processing
# ============================================================================
# Tests the batch infrastructure against the real Alpha Vantage API.
# No S3 writes — just validates build → fire → parse flow and measures timing.
#
# Usage:
#   Rscript scripts/test_batch_local.R
#
# Requires: ALPHA_VANTAGE_API_KEY environment variable
# ============================================================================

devtools::load_all()

# ============================================================================
# CONFIGURATION
# ============================================================================

tickers <- c("AAPL", "MSFT", "GOOGL", "AMZN", "META",
             "NVDA", "TSLA", "JPM", "JNJ", "PG")
batch_size <- as.integer(Sys.getenv("PHASE1_BATCH_SIZE", "10"))

api_key <- Sys.getenv("ALPHA_VANTAGE_API_KEY", "")
if (api_key == "") {
  stop("Set ALPHA_VANTAGE_API_KEY environment variable before running")
}

cat("=== Phase 1 Batch Smoke Test ===\n")
cat(sprintf("Tickers: %d (%s)\n", length(tickers), paste(tickers, collapse = ", ")))
cat(sprintf("Batch size: %d\n", batch_size))
cat("\n")

# ============================================================================
# BUILD BATCH PLAN (full fetch for all tickers)
# ============================================================================

batch_plan <- list()
for (ticker in tickers) {
  batch_plan[[ticker]] <- list(
    fetch_requirements = list(price = TRUE, splits = TRUE, quarterly = TRUE),
    ticker_tracking = NULL
  )
}

request_specs <- build_batch_requests(batch_plan, api_key)
n_requests <- length(request_specs)

cat(sprintf("Total API requests: %d (%d tickers x 6 data types)\n", n_requests, length(tickers)))
cat(sprintf("Theoretical sequential time: %d seconds (1 req/sec)\n", n_requests))
cat("\n")

# ============================================================================
# FIRE BATCH
# ============================================================================

cat("Firing batch via req_perform_parallel...\n")
requests <- lapply(request_specs, function(s) s$request)

batch_start <- Sys.time()
responses <- httr2::req_perform_parallel(requests, on_error = "continue")
batch_duration <- as.numeric(difftime(Sys.time(), batch_start, units = "secs"))

cat(sprintf("Batch API calls complete: %.1f seconds for %d requests\n",
            batch_duration, n_requests))
cat(sprintf("Effective rate: %.2f req/sec\n", n_requests / batch_duration))
cat("\n")

# ============================================================================
# PARSE RESPONSES
# ============================================================================

cat("Parsing responses...\n")
parse_start <- Sys.time()

results <- list()
for (i in seq_along(responses)) {
  resp <- responses[[i]]
  spec <- request_specs[[i]]
  ticker <- spec$ticker
  data_type <- spec$data_type

  if (is.null(results[[ticker]])) {
    results[[ticker]] <- list()
  }

  result <- tryCatch({
    if (inherits(resp, "error")) {
      list(success = FALSE, rows = 0L, error = conditionMessage(resp))
    } else {
      data <- parse_response_by_type(resp, ticker, data_type, spec$extra_params)
      n_rows <- if (!is.null(data) && is.data.frame(data)) nrow(data) else 0L
      list(success = TRUE, rows = n_rows, error = NULL)
    }
  }, error = function(e) {
    list(success = FALSE, rows = 0L, error = conditionMessage(e))
  })

  results[[ticker]][[data_type]] <- result
}

parse_duration <- as.numeric(difftime(Sys.time(), parse_start, units = "secs"))
total_duration <- batch_duration + parse_duration

cat(sprintf("Parsing complete: %.1f seconds\n", parse_duration))
cat("\n")

# ============================================================================
# RESULTS SUMMARY
# ============================================================================

cat("=== Per-Ticker Results ===\n")
cat(sprintf("%-8s %-8s %-8s %-8s %-8s %-8s %-8s\n",
            "Ticker", "Price", "Splits", "BalSht", "Income", "CashFl", "Earning"))

all_data_types <- c("price", "splits", "balance_sheet",
                     "income_statement", "cash_flow", "earnings")

total_success <- 0
total_fail <- 0
total_rows <- 0

for (ticker in tickers) {
  ticker_results <- results[[ticker]]
  row <- ticker

  for (dt in all_data_types) {
    r <- ticker_results[[dt]]
    if (is.null(r)) {
      row <- paste0(row, sprintf(" %-8s", "MISS"))
      total_fail <- total_fail + 1
    } else if (r$success) {
      row <- paste0(row, sprintf(" %-8s", paste0(r$rows, " rows")))
      total_success <- total_success + 1
      total_rows <- total_rows + r$rows
    } else {
      # Truncate error to fit
      err_short <- substr(r$error, 1, 30)
      row <- paste0(row, sprintf(" %-8s", "FAIL"))
      total_fail <- total_fail + 1
    }
  }
  cat(row, "\n")
}

cat("\n=== Timing Summary ===\n")
cat(sprintf("API calls:       %.1f sec (%d requests)\n", batch_duration, n_requests))
cat(sprintf("Parsing:         %.1f sec\n", parse_duration))
cat(sprintf("Total:           %.1f sec\n", total_duration))
cat(sprintf("Effective rate:  %.2f req/sec\n", n_requests / batch_duration))
cat(sprintf("Per ticker:      %.1f sec (vs ~10.8 sec sequential baseline)\n",
            total_duration / length(tickers)))
cat(sprintf("Speedup:         %.1fx vs sequential baseline\n",
            (length(tickers) * 10.8) / total_duration))
cat("\n")

cat(sprintf("Success: %d | Failed: %d | Total rows: %s\n",
            total_success, total_fail, format(total_rows, big.mark = ",")))

# Print any errors
errors <- list()
for (ticker in tickers) {
  for (dt in all_data_types) {
    r <- results[[ticker]][[dt]]
    if (!is.null(r) && !r$success) {
      errors[[length(errors) + 1]] <- sprintf("  %s/%s: %s", ticker, dt, r$error)
    }
  }
}
if (length(errors) > 0) {
  cat("\nErrors:\n")
  cat(paste(errors, collapse = "\n"), "\n")
}
