#' Calculate Next Estimated Report Date
#'
#' Predicts the next earnings report date based on historical patterns.
#'
#' @param last_fiscal_date_ending Date: Most recent quarter end date
#' @param last_reported_date Date: Most recent actual report date
#' @param median_report_delay_days integer: Historical median days from quarter-end to report (default: 45)
#' @return Date: Predicted next earnings report date
#' @keywords internal
calculate_next_estimated_report_date <- function(last_fiscal_date_ending,
                                                  last_reported_date,
                                                  median_report_delay_days = 45L) {
  if (is.na(last_fiscal_date_ending)) {
    return(as.Date(NA))
  }

  # Next quarter end is ~91 days after last quarter end
  next_fiscal_date <- last_fiscal_date_ending + 91L

  # If we have historical delay data, use it; otherwise use default
  delay <- if (is.na(median_report_delay_days)) 45L else median_report_delay_days

  next_fiscal_date + delay
}
