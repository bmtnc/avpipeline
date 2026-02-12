#' Fetch Options Data and Build IV Term Structure Artifacts
#'
#' On-demand function that fetches historical option chains from Alpha Vantage,
#' stores raw data in S3, and builds IV term structure artifacts.
#'
#' @param tickers character: Ticker symbols to process
#' @param n_weeks integer: Number of most recent weekly dates to fetch (default: 52)
#' @param bucket_name character: S3 bucket name (default: "avpipeline-artifacts-prod")
#' @param api_key character or NULL: Alpha Vantage API key (default: from env var)
#' @param region character: AWS region (default: "us-east-1")
#' @param tenors numeric: Standard tenor days for interpolation
#' @param moneyness_threshold numeric: ATM moneyness threshold (default: 0.05)
#' @param fetch logical: Whether to fetch from API (default: TRUE). Set FALSE to
#'   process existing raw data in S3 only.
#'
#' @return invisible list with processing summary
#' @export
fetch_options_and_build_artifact <- function(
    tickers,
    n_weeks = 52L,
    bucket_name = "avpipeline-artifacts-prod",
    api_key = NULL,
    region = "us-east-1",
    tenors = c(30, 60, 90, 180, 365),
    moneyness_threshold = 0.05,
    fetch = TRUE
) {
  if (!is.character(tickers) || length(tickers) == 0) {
    stop("tickers must be a non-empty character vector")
  }
  validate_character_scalar(bucket_name, allow_empty = FALSE, name = "bucket_name")
  validate_character_scalar(region, name = "region")

  tickers <- unique(tickers)
  n_weeks <- as.integer(n_weeks)

  if (fetch) {
    api_key <- get_api_key(api_key)
  }

  tickers_succeeded <- character(0)
  tickers_failed <- character(0)
  raw_results <- list()
  interp_results <- list()

  for (ticker in tickers) {
    message(sprintf("\n=== Processing %s ===", ticker))

    # Step 1: Load daily prices from S3 to derive weekly dates
    price_data <- tryCatch(
      s3_read_ticker_raw_data_single(ticker, "price", bucket_name, region),
      error = function(e) NULL
    )

    if ((is.null(price_data) || nrow(price_data) == 0) && fetch) {
      message(sprintf("  No price data in S3 for %s, fetching...", ticker))
      price_data <- tryCatch({
        pd <- fetch_price(ticker, api_key = api_key, outputsize = "full", datatype = "csv")
        s3_write_ticker_raw_data(pd, ticker, "price", bucket_name, region)
        message(sprintf("  Price data fetched (%d rows) and written to S3", nrow(pd)))
        pd
      }, error = function(e) {
        message(sprintf("  ERROR fetching price: %s", conditionMessage(e)))
        NULL
      })
    }

    if (is.null(price_data) || nrow(price_data) == 0) {
      message(sprintf("  SKIP: No price data available for %s", ticker))
      tickers_failed <- c(tickers_failed, ticker)
      next
    }

    # Step 2: Derive weekly observation dates
    weekly_dates <- derive_weekly_dates(price_data, n_weeks)
    message(sprintf("  %d weekly dates derived (latest: %s)",
                    length(weekly_dates), format(weekly_dates[1])))

    # Step 3: Determine which dates need fetching
    if (fetch) {
      existing_options <- tryCatch(
        s3_read_ticker_raw_data_single(ticker, "historical_options", bucket_name, region),
        error = function(e) NULL
      )

      existing_dates <- if (!is.null(existing_options) && nrow(existing_options) > 0) {
        unique(existing_options$date)
      } else {
        as.Date(character())
      }

      missing_dates <- weekly_dates[!weekly_dates %in% existing_dates]
      message(sprintf("  %d dates already in S3, %d to fetch",
                      length(weekly_dates) - length(missing_dates), length(missing_dates)))

      # Step 4: Fetch missing dates
      if (length(missing_dates) > 0) {
        fetch_result <- tryCatch(
          fetch_historical_options_for_dates(
            ticker, missing_dates, bucket_name, api_key, region
          ),
          error = function(e) {
            message(sprintf("  ERROR fetching: %s", conditionMessage(e)))
            NULL
          }
        )

        if (!is.null(fetch_result)) {
          message(sprintf("  Fetched: %d succeeded, %d failed, %d total rows in S3",
                          fetch_result$success_count, fetch_result$fail_count,
                          fetch_result$total_rows))
        }
      }
    }

    # Step 5: Read complete options data from S3
    options_data <- tryCatch(
      s3_read_ticker_raw_data_single(ticker, "historical_options", bucket_name, region),
      error = function(e) NULL
    )

    if (is.null(options_data) || nrow(options_data) == 0) {
      message(sprintf("  SKIP: No options data for %s", ticker))
      tickers_failed <- c(tickers_failed, ticker)
      next
    }

    # Step 6: Build term structures
    message(sprintf("  Building term structure (%d observation dates)...",
                    length(unique(options_data$date))))

    ts_result <- tryCatch(
      build_options_term_structure(
        ticker, options_data, price_data, tenors, moneyness_threshold
      ),
      error = function(e) {
        message(sprintf("  ERROR processing: %s", conditionMessage(e)))
        NULL
      }
    )

    if (!is.null(ts_result) && nrow(ts_result$raw_term_structure) > 0) {
      raw_results[[ticker]] <- ts_result$raw_term_structure
      interp_results[[ticker]] <- ts_result$interpolated_term_structure
      tickers_succeeded <- c(tickers_succeeded, ticker)
      message(sprintf("  OK: %d raw rows, %d interpolated rows",
                      nrow(ts_result$raw_term_structure),
                      nrow(ts_result$interpolated_term_structure)))
    } else {
      tickers_failed <- c(tickers_failed, ticker)
      message(sprintf("  SKIP: No valid term structure for %s", ticker))
    }
  }

  # Combine and upload artifacts
  combined_raw <- dplyr::bind_rows(raw_results)
  combined_interp <- dplyr::bind_rows(interp_results)

  if (nrow(combined_raw) > 0) {
    date_string <- format(Sys.Date(), "%Y-%m-%d")
    message(sprintf("\nUploading artifacts to S3 (date key: %s)...", date_string))

    raw_path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(combined_raw, raw_path)
    upload_artifact_to_s3(
      raw_path, bucket_name,
      paste0("options-artifacts/", date_string, "/raw_term_structure.parquet"),
      region
    )
    unlink(raw_path)
    message(sprintf("  Raw term structure: %d rows", nrow(combined_raw)))

    interp_path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(combined_interp, interp_path)
    upload_artifact_to_s3(
      interp_path, bucket_name,
      paste0("options-artifacts/", date_string, "/interpolated_term_structure.parquet"),
      region
    )
    unlink(interp_path)
    message(sprintf("  Interpolated term structure: %d rows", nrow(combined_interp)))
  } else {
    message("\nNo data to upload.")
  }

  message(sprintf("\nDone. %d succeeded, %d failed.",
                  length(tickers_succeeded), length(tickers_failed)))

  invisible(list(
    raw_rows = nrow(combined_raw),
    interpolated_rows = nrow(combined_interp),
    tickers_succeeded = tickers_succeeded,
    tickers_failed = unique(tickers_failed)
  ))
}
