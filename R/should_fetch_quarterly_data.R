#' Check if Quarterly Data Should Be Fetched
#'
#' Determines if quarterly data should be fetched based on earnings timing.
#'
#' @param next_estimated_report_date Date: Predicted next earnings date (can be NA)
#' @param quarterly_last_fetched_at POSIXct: Last fetch timestamp (can be NA)
#' @param reference_date Date: Date to check against (defaults to today)
#' @param window_days integer: Days before/after earnings to trigger fetch (default: 5)
#' @param fallback_max_days integer: Force fetch if data older than this (default: 90)
#' @param statements_lag_earnings logical: Whether the last fetch found statements
#'   trailing earnings' latest fiscal quarter (default: FALSE)
#' @param last_reported_date Date: Most recent earnings report date (can be NA)
#' @param lag_retry_max_days integer: Keep retrying lagged statements until this
#'   many days after the report (default: 45)
#' @return logical: TRUE if quarterly data should be fetched
#' @keywords internal
should_fetch_quarterly_data <- function(
  next_estimated_report_date,
  quarterly_last_fetched_at,
  reference_date = Sys.Date(),
  window_days = 5,
  fallback_max_days = 90,
  statements_lag_earnings = FALSE,
  last_reported_date = as.Date(NA),
  lag_retry_max_days = 45
) {
  validate_date_type(reference_date, scalar = TRUE, name = "reference_date")

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

  # Statements trailed earnings on the last fetch: keep retrying until AV
  # catches up, bounded so permanent coverage gaps don't poll forever
  if (isTRUE(statements_lag_earnings) && !is.na(last_reported_date)) {
    days_since_report <- as.numeric(difftime(
      reference_date,
      last_reported_date,
      units = "days"
    ))
    if (days_since_report <= lag_retry_max_days) {
      return(TRUE)
    }
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
