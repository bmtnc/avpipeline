#' Migrate Tracking Schema
#'
#' Adds any missing columns to tracking dataframe for schema evolution.
#'
#' @param tracking tibble: Existing tracking dataframe
#' @return tibble: Tracking with all required columns
#' @keywords internal
migrate_tracking_schema <- function(tracking) {
  if (!"overview_last_fetched_at" %in% names(tracking)) {
    tracking$overview_last_fetched_at <- as.POSIXct(NA)
  }

  if (!"price_last_date" %in% names(tracking)) {
    tracking$price_last_date <- as.Date(NA)
  }

  if (!"price_has_full_history" %in% names(tracking)) {
    tracking$price_has_full_history <- FALSE
  }

  tracking
}
