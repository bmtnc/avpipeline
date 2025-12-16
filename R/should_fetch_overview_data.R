#' Determine if Overview Data Should Be Fetched
#'
#' Returns TRUE if overview data should be fetched (never fetched or >90 days stale).
#'
#' @param overview_last_fetched_at POSIXct: Last time overview was fetched (or NA)
#' @param reference_date Date: Date to check against (defaults to today)
#' @return logical: TRUE if should fetch overview data
#' @keywords internal
should_fetch_overview_data <- function(
  overview_last_fetched_at,
  reference_date = Sys.Date()
) {
  if (!inherits(reference_date, "Date")) {
    stop("should_fetch_overview_data(): [reference_date] must be a Date object")
  }

  fallback_max_days <- DATA_TYPE_REFRESH_CONFIG$overview$fallback_max_days

  if (is.na(overview_last_fetched_at)) {
    return(TRUE)
  }

  days_since_fetch <- as.numeric(
    difftime(reference_date, as.Date(overview_last_fetched_at), units = "days")
  )

  days_since_fetch > fallback_max_days
}
