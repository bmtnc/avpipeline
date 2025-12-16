#' Update Tracking After Successful Fetch
#'
#' Convenience function to update tracking after fetching data for a ticker.
#'
#' @param tracking tibble: Full refresh tracking dataframe
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data fetched ("price", "splits", or "quarterly")
#' @param fiscal_date_ending Date: Most recent fiscalDateEnding (for quarterly only)
#' @param reported_date Date: Most recent reportedDate (for quarterly only)
#' @param price_last_date Date: Most recent date in price data (for price only)
#' @param price_has_full_history logical: Whether full history was fetched (for price only)
#' @param data_changed logical: Whether data actually changed from previous fetch
#' @return tibble: Updated tracking dataframe
#' @keywords internal
update_tracking_after_fetch <- function(
  tracking,
  ticker,
  data_type,
  fiscal_date_ending = NULL,
  reported_date = NULL,
  price_last_date = NULL,
  price_has_full_history = NULL,
  data_changed = FALSE
) {
  if (!is.character(data_type) || length(data_type) != 1) {
    stop(
      "update_tracking_after_fetch(): [data_type] must be a character scalar"
    )
  }

  now <- Sys.time()
  updates <- list()

  if (data_type == "price") {
    updates$price_last_fetched_at <- now
    if (!is.null(price_last_date)) {
      updates$price_last_date <- price_last_date
    }
    if (!is.null(price_has_full_history)) {
      updates$price_has_full_history <- price_has_full_history
    }
  } else if (data_type == "splits") {
    updates$splits_last_fetched_at <- now
  } else if (data_type == "quarterly") {
    updates$quarterly_last_fetched_at <- now
    if (!is.null(fiscal_date_ending)) {
      updates$last_fiscal_date_ending <- fiscal_date_ending
    }
    if (!is.null(reported_date)) {
      updates$last_reported_date <- reported_date
    }
  } else if (data_type == "overview") {
    updates$overview_last_fetched_at <- now
  }

  if (data_changed) {
    updates$data_updated_at <- now
  }

  updates$last_error_message <- NA_character_

  update_ticker_tracking(tracking, ticker, updates)
}
