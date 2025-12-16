#' Create Default Tracking Row for New Ticker
#'
#' Creates a default tracking row for a ticker not yet in tracking.
#'
#' @param ticker character: Stock symbol
#' @return tibble: Single row with default values
#' @keywords internal
create_default_ticker_tracking <- function(ticker) {
  if (!is.character(ticker) || length(ticker) != 1 || nchar(ticker) == 0) {
    stop("create_default_ticker_tracking(): [ticker] must be a non-empty character scalar")
  }

  tibble::tibble(
    ticker = ticker,
    price_last_fetched_at = as.POSIXct(NA),
    splits_last_fetched_at = as.POSIXct(NA),
    quarterly_last_fetched_at = as.POSIXct(NA),
    last_fiscal_date_ending = as.Date(NA),
    last_reported_date = as.Date(NA),
    next_estimated_report_date = as.Date(NA),
    median_report_delay_days = NA_integer_,
    last_error_message = NA_character_,
    is_active_ticker = TRUE,
    has_data_discrepancy = FALSE,
    last_version_date = as.Date(NA),
    data_updated_at = as.POSIXct(NA)
  )
}
