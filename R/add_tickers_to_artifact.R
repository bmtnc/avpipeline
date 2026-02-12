#' Add Tickers to Artifact
#'
#' Fetches raw data for specific tickers, processes them, and merges into the
#' existing S3 artifacts. Runs locally for ad-hoc additions outside the regular
#' pipeline.
#'
#' @param tickers character: Ticker symbols to add or refresh
#' @param bucket_name character: S3 bucket name (default: "avpipeline-artifacts-prod")
#' @param api_key character or NULL: Alpha Vantage API key (default: from env var)
#' @param region character: AWS region (default: "us-east-1")
#' @param start_date Date: Start date for data filtering (default: 2004-12-31)
#' @param fetch logical: Whether to fetch raw data from API (default: TRUE).
#'   Set FALSE if raw data is already in S3.
#' @return invisible list with quarterly_rows_added, price_rows_added,
#'   tickers_succeeded, tickers_failed
#' @export
add_tickers_to_artifact <- function(
    tickers,
    bucket_name = "avpipeline-artifacts-prod",
    api_key = NULL,
    region = "us-east-1",
    start_date = as.Date("2004-12-31"),
    fetch = TRUE
) {

  if (!is.character(tickers) || length(tickers) == 0) {
    stop("add_tickers_to_artifact(): [tickers] must be a non-empty character vector")
  }
  validate_character_scalar(bucket_name, allow_empty = FALSE, name = "bucket_name")
  validate_character_scalar(region, name = "region")

  tickers <- unique(tickers)
  tickers_succeeded <- character(0)
  tickers_failed <- character(0)

  # ---- Phase 1: Fetch ----

  if (fetch) {
    api_key <- get_api_key(api_key)
    message(sprintf("Phase 1: Fetching %d ticker(s)...", length(tickers)))

    tracking <- s3_read_refresh_tracking(bucket_name, region)
    fetch_requirements <- list(price = TRUE, splits = TRUE, quarterly = TRUE)

    for (ticker in tickers) {
      message(sprintf("  Fetching %s...", ticker))
      ticker_tracking <- get_ticker_tracking(ticker, tracking)

      ticker_results <- tryCatch({
        fetch_and_store_ticker_data(
          ticker = ticker,
          fetch_requirements = fetch_requirements,
          ticker_tracking = ticker_tracking,
          bucket_name = bucket_name,
          api_key = api_key,
          region = region
        )
      }, error = function(e) {
        message(sprintf("    ERROR: %s", conditionMessage(e)))
        NULL
      })

      if (is.null(ticker_results)) {
        tracking <- update_tracking_after_error(tracking, ticker, "Fetch failed")
        tickers_failed <- c(tickers_failed, ticker)
        next
      }

      any_error <- any(sapply(ticker_results, function(r) !isTRUE(r$success)))
      if (any_error) {
        error_msgs <- sapply(ticker_results, function(r) r$error)
        error_msgs <- error_msgs[!sapply(error_msgs, is.null)]
        tracking <- update_tracking_after_error(
          tracking, ticker, paste(error_msgs, collapse = "; ")
        )
        tickers_failed <- c(tickers_failed, ticker)
        message(sprintf("    FAILED: %s", paste(error_msgs, collapse = "; ")))
        next
      }

      # Update tracking (same pattern as run_phase1_fetch.R:216-246)
      if (!is.null(ticker_results$price)) {
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

      if (!is.null(ticker_results$splits)) {
        tracking <- update_tracking_after_fetch(tracking, ticker, "splits")
      }

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

      tickers_succeeded <- c(tickers_succeeded, ticker)
      message(sprintf("    OK"))
    }

    s3_write_refresh_tracking(tracking, bucket_name, region)
    message("Tracking saved to S3")
  } else {
    tickers_succeeded <- tickers
    message("Skipping Phase 1 (fetch = FALSE)")
  }

  tickers_to_process <- if (fetch) tickers_succeeded else tickers

  if (length(tickers_to_process) == 0) {
    message("No tickers to process")
    return(invisible(list(
      quarterly_rows_added = 0L,
      price_rows_added = 0L,
      tickers_succeeded = tickers_succeeded,
      tickers_failed = tickers_failed
    )))
  }

  # ---- Phase 2: Process ----

  message(sprintf("Phase 2: Processing %d ticker(s)...", length(tickers_to_process)))

  quarterly_results <- list()
  price_results <- list()

  for (ticker in tickers_to_process) {
    message(sprintf("  Processing %s...", ticker))

    raw <- tryCatch(
      s3_read_ticker_raw_data(ticker, bucket_name, region),
      error = function(e) {
        message(sprintf("    ERROR reading raw data: %s", conditionMessage(e)))
        NULL
      }
    )
    if (is.null(raw)) {
      tickers_failed <- c(tickers_failed, ticker)
      tickers_succeeded <- setdiff(tickers_succeeded, ticker)
      next
    }

    # Structure into pre-split all_data format
    all_data <- list(
      balance_sheet    = setNames(list(raw$balance_sheet %||% tibble::tibble()), ticker),
      income_statement = setNames(list(raw$income_statement %||% tibble::tibble()), ticker),
      cash_flow        = setNames(list(raw$cash_flow %||% tibble::tibble()), ticker),
      earnings         = setNames(list(raw$earnings %||% tibble::tibble()), ticker),
      overview         = setNames(list(raw$overview %||% tibble::tibble()), ticker)
    )

    quarterly <- tryCatch(
      process_ticker_for_quarterly_artifact(
        ticker = ticker,
        all_data = all_data,
        start_date = start_date
      ),
      error = function(e) {
        message(sprintf("    ERROR processing: %s", conditionMessage(e)))
        NULL
      }
    )

    if (!is.null(quarterly) && nrow(quarterly) > 0) {
      quarterly_results[[ticker]] <- quarterly
    }

    # Collect price data
    if (!is.null(raw$price) && nrow(raw$price) > 0) {
      price_results[[ticker]] <- raw$price |>
        dplyr::filter(date >= start_date, !is.na(close) & close > 0) |>
        dplyr::select(
          ticker, date, open, high, low, close, adjusted_close,
          volume, dividend_amount, split_coefficient
        ) |>
        dplyr::distinct() |>
        dplyr::arrange(ticker, date)
    }

    message(sprintf("    OK (%d quarterly rows, %d price rows)",
      if (!is.null(quarterly)) nrow(quarterly) else 0L,
      if (!is.null(price_results[[ticker]])) nrow(price_results[[ticker]]) else 0L
    ))
  }

  new_quarterly <- dplyr::bind_rows(quarterly_results)
  new_price <- dplyr::bind_rows(price_results)

  # ---- Merge with existing artifacts ----

  message("Loading existing artifacts from S3...")

  existing_quarterly <- tryCatch(
    load_quarterly_artifact(bucket_name, region = region),
    error = function(e) {
      message(sprintf("No existing quarterly artifact: %s", e$message))
      tibble::tibble()
    }
  )

  existing_price <- tryCatch(
    load_price_artifact(bucket_name, region = region),
    error = function(e) {
      message(sprintf("No existing price artifact: %s", e$message))
      tibble::tibble()
    }
  )

  # Upsert: remove existing rows for these tickers, then bind new
  processed_tickers <- unique(c(
    if (nrow(new_quarterly) > 0) unique(new_quarterly$ticker) else character(0),
    if (nrow(new_price) > 0) unique(new_price$ticker) else character(0)
  ))

  if (nrow(existing_quarterly) > 0 && length(processed_tickers) > 0) {
    existing_quarterly <- dplyr::filter(
      existing_quarterly, !ticker %in% processed_tickers
    )
  }
  if (nrow(existing_price) > 0 && length(processed_tickers) > 0) {
    existing_price <- dplyr::filter(
      existing_price, !ticker %in% processed_tickers
    )
  }

  merged_quarterly <- dplyr::bind_rows(existing_quarterly, new_quarterly)
  merged_price <- dplyr::bind_rows(existing_price, new_price)

  # ---- Upload merged artifacts ----

  date_string <- format(Sys.Date(), "%Y-%m-%d")
  message(sprintf("Uploading merged artifacts to S3 (date key: %s)...", date_string))

  quarterly_path <- tempfile(fileext = ".parquet")
  arrow::write_parquet(merged_quarterly, quarterly_path)
  upload_artifact_to_s3(
    quarterly_path, bucket_name,
    paste0("ttm-artifacts/", date_string, "/ttm_quarterly_artifact.parquet"),
    region
  )
  unlink(quarterly_path)
  message(sprintf("  Quarterly artifact: %d rows (%d new)",
    nrow(merged_quarterly), nrow(new_quarterly)))

  price_path <- tempfile(fileext = ".parquet")
  arrow::write_parquet(merged_price, price_path)
  upload_artifact_to_s3(
    price_path, bucket_name,
    paste0("ttm-artifacts/", date_string, "/price_artifact.parquet"),
    region
  )
  unlink(price_path)
  message(sprintf("  Price artifact: %d rows (%d new)",
    nrow(merged_price), nrow(new_price)))

  message("Done.")

  invisible(list(
    quarterly_rows_added = nrow(new_quarterly),
    price_rows_added = nrow(new_price),
    tickers_succeeded = tickers_succeeded,
    tickers_failed = unique(tickers_failed)
  ))
}
