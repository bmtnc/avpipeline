#!/usr/bin/env Rscript

# ============================================================================
# Phase 1 Integration Test: QQQ Only
# ============================================================================
# Runs the full batch flow (API → parse → S3 write → tracking) for QQQ
# tickers only (~100 tickers). Does NOT union with existing S3 tickers.
#
# Usage:
#   S3_BUCKET=avpipeline-artifacts-prod Rscript scripts/test_phase1_qqq.R
# ============================================================================

devtools::load_all()

# ============================================================================
# CONFIGURATION
# ============================================================================

etf_symbol <- "QQQ"
aws_region <- Sys.getenv("AWS_REGION", "us-east-1")
s3_bucket <- Sys.getenv("S3_BUCKET")
fetch_mode <- "full"
batch_size <- as.integer(Sys.getenv("PHASE1_BATCH_SIZE", "25"))

if (s3_bucket == "") {
  stop("S3_BUCKET environment variable is required")
}

phase_start_time <- Sys.time()
log_phase_start("PHASE 1 TEST: QQQ ONLY",
  sprintf("ETF: %s | Bucket: %s | Batch size: %d", etf_symbol, s3_bucket, batch_size)
)

# ============================================================================
# SETUP — QQQ tickers only, no S3 union
# ============================================================================

api_key <- get_api_key_from_parameter_store(
  parameter_name = "/avpipeline/alpha-vantage-api-key",
  region = aws_region
)
Sys.setenv(ALPHA_VANTAGE_API_KEY = api_key)

tracking <- s3_read_refresh_tracking(s3_bucket, aws_region)

# QQQ tickers only — skip S3 union for testing
tickers <- get_financial_statement_tickers(etf_symbol = etf_symbol)
n_tickers <- length(tickers)

log_pipeline(sprintf("QQQ tickers: %d (no S3 union)", n_tickers))

# ============================================================================
# PRE-COMPUTE FETCH REQUIREMENTS
# ============================================================================

pipeline_log <- create_pipeline_log()
reference_date <- Sys.Date()
success_count <- 0
error_count <- 0
skip_count <- 0
failed_tickers <- character(0)

batch_plan_all <- list()
skip_tickers <- character(0)

log_pipeline("Pre-computing fetch requirements...")

for (ticker in tickers) {
  tryCatch({
    ticker_tracking <- get_ticker_tracking(ticker, tracking)
    fetch_requirements <- determine_fetch_requirements(
      ticker_tracking, reference_date, fetch_mode = fetch_mode
    )
    fetch_types <- names(fetch_requirements)[unlist(fetch_requirements)]

    if (length(fetch_types) == 0) {
      skip_tickers <- c(skip_tickers, ticker)
    } else {
      batch_plan_all[[ticker]] <- list(
        fetch_requirements = fetch_requirements,
        ticker_tracking = ticker_tracking
      )
    }
  }, error = function(e) {
    error_count <<- error_count + 1
    failed_tickers <<- c(failed_tickers, ticker)
    tracking <<- update_tracking_after_error(tracking, ticker, conditionMessage(e))
  })
}

for (ticker in skip_tickers) {
  skip_count <- skip_count + 1
}

log_pipeline(sprintf("Fetch plan: %d to fetch | %d skipped | %d errors",
                     length(batch_plan_all), skip_count, error_count))

# ============================================================================
# BATCH PROCESSING
# ============================================================================

tickers_to_fetch <- names(batch_plan_all)
n_to_fetch <- length(tickers_to_fetch)

if (n_to_fetch > 0) {
  n_batches <- ceiling(n_to_fetch / batch_size)
  n_total_requests <- sum(sapply(batch_plan_all, function(p) {
    reqs <- p$fetch_requirements
    sum(c(isTRUE(reqs$price), isTRUE(reqs$splits), isTRUE(reqs$quarterly) * 4))
  }))

  log_pipeline(sprintf("Processing %d tickers in %d batches (%d total API requests)",
                       n_to_fetch, n_batches, n_total_requests))
  log_pipeline(sprintf("Theoretical sequential time: %d sec (%.1f min)",
                       n_total_requests, n_total_requests / 60))

  loop_start_time <- Sys.time()
  processed_count <- 0

  for (batch_idx in seq_len(n_batches)) {
    batch_start <- (batch_idx - 1) * batch_size + 1
    batch_end <- min(batch_idx * batch_size, n_to_fetch)
    batch_tickers <- tickers_to_fetch[batch_start:batch_end]
    batch_start_time <- Sys.time()

    log_pipeline(sprintf("Batch %d/%d: %d tickers (%s...)",
                         batch_idx, n_batches, length(batch_tickers),
                         paste(batch_tickers[1:min(3, length(batch_tickers))], collapse = ", ")))

    batch_plan <- batch_plan_all[batch_tickers]

    tryCatch({
      request_specs <- build_batch_requests(batch_plan, api_key)

      if (length(request_specs) > 0) {
        requests <- lapply(request_specs, function(s) s$request)
        responses <- httr2::req_perform_parallel(requests, on_error = "continue")
        batch_results <- process_batch_responses(
          responses, request_specs, s3_bucket, aws_region
        )
      } else {
        batch_results <- list()
      }

      for (ticker in batch_tickers) {
        ticker_results <- batch_results[[ticker]]

        if (is.null(ticker_results)) {
          error_count <- error_count + 1
          failed_tickers <- c(failed_tickers, ticker)
          tracking <- update_tracking_after_error(
            tracking, ticker, "No responses received"
          )
          next
        }

        any_error <- any(sapply(ticker_results, function(r) !isTRUE(r$success)))
        fetch_requirements <- batch_plan[[ticker]]$fetch_requirements

        if (any_error) {
          error_count <- error_count + 1
          failed_tickers <- c(failed_tickers, ticker)
          error_msgs <- sapply(ticker_results, function(r) r$error)
          error_msgs <- error_msgs[!sapply(error_msgs, is.null)]
          tracking <- update_tracking_after_error(
            tracking, ticker, paste(error_msgs, collapse = "; ")
          )
        } else {
          success_count <- success_count + 1

          if (isTRUE(fetch_requirements$price) && !is.null(ticker_results$price)) {
            price_data <- ticker_results$price$data
            price_last_date <- if (!is.null(price_data) && nrow(price_data) > 0) {
              max(price_data$date, na.rm = TRUE)
            } else {
              NULL
            }
            tracking <- update_tracking_after_fetch(
              tracking, ticker, "price",
              price_last_date = price_last_date,
              price_has_full_history = TRUE
            )
          }

          if (isTRUE(fetch_requirements$splits)) {
            tracking <- update_tracking_after_fetch(tracking, ticker, "splits")
          }

          if (isTRUE(fetch_requirements$quarterly)) {
            earnings_data <- ticker_results$earnings$data
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
        }

        processed_count <- processed_count + 1
      }

    }, error = function(e) {
      for (ticker in batch_tickers) {
        error_count <<- error_count + 1
        failed_tickers <<- c(failed_tickers, ticker)
        tracking <<- update_tracking_after_error(tracking, ticker, conditionMessage(e))
        processed_count <<- processed_count + 1
      }
    })

    batch_duration <- as.numeric(difftime(Sys.time(), batch_start_time, units = "secs"))
    elapsed <- as.numeric(difftime(Sys.time(), loop_start_time, units = "secs"))
    log_progress_summary(processed_count, n_to_fetch, success_count, error_count,
                         elapsed_seconds = elapsed)
    gc(verbose = FALSE)
  }
}

# Save tracking (but don't clear any checkpoint since this is a test)
s3_write_refresh_tracking(tracking, s3_bucket, aws_region)

# ============================================================================
# SUMMARY
# ============================================================================

phase_duration <- as.numeric(difftime(Sys.time(), phase_start_time, units = "secs"))
log_phase_end("PHASE 1 TEST: QQQ ONLY",
  total = n_tickers,
  successful = success_count + skip_count,
  failed = error_count,
  duration_seconds = phase_duration
)
log_failed_tickers(failed_tickers)

cat(sprintf("\n=== Timing ===\n"))
cat(sprintf("Total duration:     %.1f sec (%.1f min)\n", phase_duration, phase_duration / 60))
cat(sprintf("Per ticker:         %.1f sec\n", phase_duration / n_tickers))
cat(sprintf("Sequential baseline: %.1f sec (10.8 sec/ticker)\n", n_tickers * 10.8))
cat(sprintf("Speedup:            %.1fx\n", (n_tickers * 10.8) / phase_duration))
