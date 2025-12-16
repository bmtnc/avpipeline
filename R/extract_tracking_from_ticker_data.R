#' Extract Tracking Info from Ticker Data
#'
#' Extracts tracking metadata from existing ticker data files.
#'
#' @param ticker character: Stock symbol
#' @param price_data tibble: Price data (or NULL)
#' @param earnings_data tibble: Earnings data (or NULL)
#' @return tibble: Single row tracking entry
#' @keywords internal
extract_tracking_from_ticker_data <- function(ticker, price_data, earnings_data) {
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("extract_tracking_from_ticker_data(): [ticker] must be a character scalar")
  }

  row <- create_default_ticker_tracking(ticker)

  if (!is.null(price_data) && nrow(price_data) > 0) {
    if ("date" %in% names(price_data)) {
      row$price_last_date <- max(price_data$date, na.rm = TRUE)
      row$price_has_full_history <- TRUE
      row$price_last_fetched_at <- as.POSIXct(NA)
    }
  }

  if (!is.null(earnings_data) && nrow(earnings_data) > 0) {
    if ("fiscalDateEnding" %in% names(earnings_data)) {
      row$last_fiscal_date_ending <- max(earnings_data$fiscalDateEnding, na.rm = TRUE)
      row$quarterly_last_fetched_at <- as.POSIXct(NA)
    }
    if ("reportedDate" %in% names(earnings_data)) {
      row$last_reported_date <- max(earnings_data$reportedDate, na.rm = TRUE)
    }
  }

  row
}
