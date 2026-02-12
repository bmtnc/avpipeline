#' Fetch and Store All Required Data for a Ticker
#'
#' Orchestrates fetching all required data types for a ticker based on fetch requirements.
#' Uses smart price fetching: compact by default if has full history and <90 days stale.
#' If split detected in compact response, refetches with full.
#'
#' @param ticker character: Stock symbol
#' @param fetch_requirements list: Output from determine_fetch_requirements()
#' @param ticker_tracking tibble: Single row tracking data for this ticker
#' @param bucket_name character: S3 bucket name
#' @param api_key character: Alpha Vantage API key
#' @param region character: AWS region (default: "us-east-1")
#' @param delay_seconds numeric: Delay after each API call (default: 1)
#' @return list: results per data type, each with success/data/error/metadata
#' @keywords internal
fetch_and_store_ticker_data <- function(
  ticker,
  fetch_requirements,
  ticker_tracking,
  bucket_name,
  api_key,
  region = "us-east-1",
  delay_seconds = 1
) {
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("fetch_and_store_ticker_data(): [ticker] must be a character scalar")
  }
  if (!is.list(fetch_requirements)) {
    stop("fetch_and_store_ticker_data(): [fetch_requirements] must be a list")
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("fetch_and_store_ticker_data(): [bucket_name] must be a character scalar")
  }

  results <- list()

  if (isTRUE(fetch_requirements$price)) {
    # Always fetch full price history to avoid data loss from compact overwrites
    results$price <- fetch_and_store_single_data_type(
      ticker, "price", bucket_name, api_key, region, delay_seconds,
      outputsize = "full"
    )
  }

  if (isTRUE(fetch_requirements$splits)) {
    results$splits <- fetch_and_store_single_data_type(
      ticker, "splits", bucket_name, api_key, region, delay_seconds
    )
  }

  if (isTRUE(fetch_requirements$quarterly)) {
    quarterly_types <- c("balance_sheet", "income_statement", "cash_flow", "earnings", "earnings_estimates")
    for (data_type in quarterly_types) {
      results[[data_type]] <- fetch_and_store_single_data_type(
        ticker, data_type, bucket_name, api_key, region, delay_seconds
      )
    }
  }

  results
}
