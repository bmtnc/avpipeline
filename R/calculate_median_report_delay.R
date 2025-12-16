#' Calculate Median Report Delay
#'
#' Calculates the median delay between quarter end and report date from historical data.
#'
#' @param earnings_data data.frame: Earnings data with fiscalDateEnding and reportedDate
#' @return integer: Median delay in days, or NA if insufficient data
#' @keywords internal
calculate_median_report_delay <- function(earnings_data) {
  required_cols <- c("fiscalDateEnding", "reportedDate")
  validate_df_cols(earnings_data, required_cols)

  if (nrow(earnings_data) == 0) {
    return(NA_integer_)
  }

  valid_rows <- earnings_data[
    !is.na(earnings_data$fiscalDateEnding) & !is.na(earnings_data$reportedDate),
  ]

  if (nrow(valid_rows) < 2) {
    return(NA_integer_)
  }

  delays <- as.numeric(difftime(
    valid_rows$reportedDate,
    valid_rows$fiscalDateEnding,
    units = "days"
  ))

  as.integer(round(median(delays, na.rm = TRUE)))
}
