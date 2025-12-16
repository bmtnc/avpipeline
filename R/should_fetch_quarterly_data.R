#' Check if Quarterly Data Should Be Fetched
#'
#' Determines if quarterly data should be fetched based on earnings timing.
#'
#' @param next_estimated_report_date Date: Predicted next earnings date (can be NA)
#' @param quarterly_last_fetched_at POSIXct: Last fetch timestamp (can be NA)
#' @param reference_date Date: Date to check against (defaults to today)
#' @param window_days integer: Days before/after earnings to trigger fetch (default: 5)
#' @param fallback_max_days integer: Force fetch if data older than this (default: 90)
#' @return logical: TRUE if quarterly data should be fetched
#' @keywords internal
should_fetch_quarterly_data <- function(
  next_estimated_report_date,
  quarterly_last_fetched_at,
  reference_date = Sys.Date(),
  window_days = DATA_TYPE_REFRESH_CONFIG$quarterly$window_days,
  fallback_max_days = DATA_TYPE_REFRESH_CONFIG$quarterly$fallback_max_days
) {
  if (!inherits(reference_date, "Date")) {
    stop(
      "should_fetch_quarterly_data(): [reference_date] must be a Date object"
    )
  }

  # New ticker - no prior fetch
  if (is.na(quarterly_last_fetched_at)) {
    return(TRUE)
  }

  # Fallback: fetch if data is too old
  days_since_fetch <- as.numeric(difftime(
    reference_date,
    as.Date(quarterly_last_fetched_at),
    units = "days"
  ))
  if (days_since_fetch > fallback_max_days) {
    return(TRUE)
  }

  # No predicted date - rely on fallback
  if (is.na(next_estimated_report_date)) {
    return(FALSE)
  }

  # Within ±window_days of predicted earnings
  days_until_earnings <- as.numeric(difftime(
    next_estimated_report_date,
    reference_date,
    units = "days"
  ))
  abs(days_until_earnings) <= window_days
}
