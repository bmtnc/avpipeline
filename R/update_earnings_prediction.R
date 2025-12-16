#' Update Earnings Prediction After Fetch
#'
#' Updates the tracking with new earnings prediction based on freshly fetched data.
#'
#' @param tracking tibble: Full refresh tracking dataframe
#' @param ticker character: Stock symbol
#' @param earnings_data data.frame: Freshly fetched earnings data
#' @return tibble: Updated tracking dataframe
#' @keywords internal
update_earnings_prediction <- function(tracking, ticker, earnings_data) {
  if (!is.data.frame(tracking)) {
    stop("update_earnings_prediction(): [tracking] must be a data.frame")
  }
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("update_earnings_prediction(): [ticker] must be a character scalar")
  }
  if (!is.data.frame(earnings_data)) {
    stop("update_earnings_prediction(): [earnings_data] must be a data.frame")
  }
  if (nrow(earnings_data) == 0) {
    return(tracking)
  }

  # Get latest dates from earnings data
  last_fiscal <- max(earnings_data$fiscalDateEnding, na.rm = TRUE)
  last_reported <- max(earnings_data$reportedDate, na.rm = TRUE)

  # Calculate median delay
  median_delay <- calculate_median_report_delay(earnings_data)

  # Predict next report date
  next_estimated <- calculate_next_estimated_report_date(
    last_fiscal_date_ending = last_fiscal,
    last_reported_date = last_reported,
    median_report_delay_days = median_delay
  )

  # Update tracking
  update_ticker_tracking(
    tracking,
    ticker,
    list(
      last_fiscal_date_ending = last_fiscal,
      last_reported_date = last_reported,
      median_report_delay_days = median_delay,
      next_estimated_report_date = next_estimated
    )
  )
}
