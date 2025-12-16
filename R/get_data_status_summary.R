#' Get Data Status Summary
#'
#' Returns a summary of data freshness for all tracked tickers.
#'
#' @param tracking tibble: Refresh tracking dataframe from s3_read_refresh_tracking()
#' @param reference_date Date: Date to compare against (default: Sys.Date())
#' @return tibble: Summary with staleness info for each ticker
#' @export
get_data_status_summary <- function(tracking, reference_date = Sys.Date()) {
  if (!is.data.frame(tracking)) {
    stop("get_data_status_summary(): [tracking] must be a data.frame")
  }
  if (!inherits(reference_date, "Date")) {
    stop("get_data_status_summary(): [reference_date] must be a Date object")
  }

  if (nrow(tracking) == 0) {
    return(tibble::tibble(
      ticker = character(),
      price_days_stale = numeric(),
      price_has_full = logical(),
      quarterly_days_stale = numeric(),
      overview_days_stale = numeric(),
      needs_price_full = logical(),
      needs_quarterly = logical()
    ))
  }

  tracking %>%
    dplyr::mutate(
      price_days_stale = as.numeric(difftime(
        reference_date, as.Date(price_last_date), units = "days"
      )),
      quarterly_days_stale = as.numeric(difftime(
        reference_date, as.Date(quarterly_last_fetched_at), units = "days"
      )),
      overview_days_stale = as.numeric(difftime(
        reference_date, as.Date(overview_last_fetched_at), units = "days"
      )),
      needs_price_full = is.na(price_has_full_history) | !price_has_full_history | price_days_stale > 90,
      needs_quarterly = is.na(quarterly_last_fetched_at) | quarterly_days_stale > 90
    ) %>%
    dplyr::select(
      ticker,
      price_days_stale,
      price_has_full = price_has_full_history,
      quarterly_days_stale,
      overview_days_stale,
      needs_price_full,
      needs_quarterly
    )
}
