#!/usr/bin/env Rscript

# ============================================================================
# Phase 1: Fetch Raw Data to S3 (Batch Mode)
# ============================================================================
# Fetches raw data from Alpha Vantage and stores per-ticker in S3.
# Uses httr2 batch processing with req_throttle for API rate limiting.
# S3 writes happen after each batch, decoupled from API pacing.
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
fetch_mode <- Sys.getenv("FETCH_MODE", "full")
batch_size <- as.integer(Sys.getenv("PHASE1_BATCH_SIZE", "25"))

if (s3_bucket == "") {
  stop("S3_BUCKET environment variable is required")
}

if (!fetch_mode %in% c("full", "price_only", "quarterly_only")) {
  stop("FETCH_MODE must be 'full', 'price_only', or 'quarterly_only'")
}

phase_start_time <- Sys.time()
log_phase_start("PHASE 1: FETCH RAW DATA",
  sprintf("ETF: %s | Bucket: %s | Mode: %s | Batch size: %d",
          etf_symbol, s3_bucket, fetch_mode, batch_size)
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
    pipeline_log <<- add_log_entry(
      pipeline_log, ticker, "fetch", "requirements", "error",
      error_message = conditionMessage(e)
    )
  })
}

# Checkpoint skipped tickers immediately
for (ticker in skip_tickers) {
  skip_count <- skip_count + 1
  checkpoint <- update_checkpoint(checkpoint, ticker, success = TRUE)
  pipeline_log <- add_log_entry(
    pipeline_log, ticker, "fetch", "all", "skipped"
  )
}

log_pipeline(sprintf("Fetch plan: %d to fetch | %d skipped | %d errors in planning",
                     length(batch_plan_all), skip_count, error_count))

# ============================================================================
# BATCH PROCESSING
# ============================================================================

tickers_to_fetch <- names(batch_plan_all)
n_to_fetch <- length(tickers_to_fetch)

if (n_to_fetch > 0) {
  n_batches <- ceiling(n_to_fetch / batch_size)
  log_pipeline(sprintf("Processing %d tickers in %d batches of up to %d",
                       n_to_fetch, n_batches, batch_size))

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
      # Build all request objects for this batch
      request_specs <- build_batch_requests(batch_plan, api_key)

      if (length(request_specs) > 0) {
        # Extract httr2 request objects
        requests <- lapply(request_specs, function(s) s$request)

        # Fire all requests with throttle-based rate limiting
        responses <- httr2::req_perform_parallel(
          requests,
          on_error = "continue"
        )

        # Process responses: parse + S3 write
        batch_results <- process_batch_responses(
          responses, request_specs, s3_bucket, aws_region
        )
      } else {
        batch_results <- list()
      }

      # Update tracking per ticker in this batch
      for (ticker in batch_tickers) {
        ticker_results <- batch_results[[ticker]]

        if (is.null(ticker_results)) {
          # No results at all for this ticker
          error_count <- error_count + 1
          failed_tickers <- c(failed_tickers, ticker)
          tracking <- update_tracking_after_error(
            tracking, ticker, "No responses received for ticker"
          )
          checkpoint <- update_checkpoint(checkpoint, ticker, success = FALSE)
          pipeline_log <- add_log_entry(
            pipeline_log, ticker, "fetch", "batch", "error",
            error_message = "No responses received for ticker"
          )
          next
        }

        any_error <- any(sapply(ticker_results, function(r) !isTRUE(r$success)))
        duration <- as.numeric(difftime(Sys.time(), batch_start_time, units = "secs"))
        fetch_requirements <- batch_plan[[ticker]]$fetch_requirements
        fetch_types <- names(fetch_requirements)[unlist(fetch_requirements)]

        if (any_error) {
          error_count <- error_count + 1
          failed_tickers <- c(failed_tickers, ticker)
          error_msgs <- sapply(ticker_results, function(r) r$error)
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

          total_rows <- sum(sapply(ticker_results, function(r) {
            if (!is.null(r$data)) nrow(r$data) else 0L
          }))

          checkpoint <- update_checkpoint(checkpoint, ticker, success = TRUE)
          pipeline_log <- add_log_entry(
            pipeline_log, ticker, "fetch", paste(fetch_types, collapse = ","),
            "success", rows = total_rows, duration_seconds = duration
          )
        }

        processed_count <- processed_count + 1
      }

    }, error = function(e) {
      # Batch-level error: mark all tickers in batch as failed
      for (ticker in batch_tickers) {
        error_count <<- error_count + 1
        failed_tickers <<- c(failed_tickers, ticker)
        tracking <<- update_tracking_after_error(tracking, ticker, conditionMessage(e))
        checkpoint <<- update_checkpoint(checkpoint, ticker, success = FALSE)
        pipeline_log <<- add_log_entry(
          pipeline_log, ticker, "fetch", "batch", "error",
          error_message = conditionMessage(e)
        )
        processed_count <<- processed_count + 1
      }
    })

    # Save checkpoint and tracking at every batch boundary
    s3_write_checkpoint(checkpoint, s3_bucket, "phase1", aws_region)
    s3_write_refresh_tracking(tracking, s3_bucket, aws_region)

    # Log progress
    elapsed <- as.numeric(difftime(Sys.time(), loop_start_time, units = "secs"))
    log_progress_summary(processed_count, n_to_fetch, success_count, error_count,
                         elapsed_seconds = elapsed)
    gc(verbose = FALSE)
  }
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
