#' Create Empty Refresh Tracking DataFrame
#'
#' Creates an empty dataframe with the refresh tracking schema.
#'
#' @return tibble: Empty dataframe with correct column types
#' @keywords internal
create_empty_refresh_tracking <- function() {
  tibble::tibble(
    ticker = character(),
    price_last_fetched_at = as.POSIXct(character()),
    splits_last_fetched_at = as.POSIXct(character()),
    quarterly_last_fetched_at = as.POSIXct(character()),
    overview_last_fetched_at = as.POSIXct(character()),
    last_fiscal_date_ending = as.Date(character()),
    last_reported_date = as.Date(character()),
    next_estimated_report_date = as.Date(character()),
    median_report_delay_days = integer(),
    last_error_message = character(),
    is_active_ticker = logical(),
    has_data_discrepancy = logical(),
    last_version_date = as.Date(character()),
    data_updated_at = as.POSIXct(character())
  )
}
