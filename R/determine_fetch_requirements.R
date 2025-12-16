#' Determine Fetch Requirements for a Ticker
#'
#' Determines which data types need to be fetched for a ticker based on tracking state.
#'
#' @param ticker_tracking tibble: Single row from refresh tracking for this ticker
#' @param reference_date Date: Date to check against (defaults to today)
#' @return list: Named list with price, splits, quarterly (each TRUE/FALSE)
#' @keywords internal
determine_fetch_requirements <- function(
  ticker_tracking,
  reference_date = Sys.Date()
) {
  if (!is.data.frame(ticker_tracking) || nrow(ticker_tracking) != 1) {
    stop(
      "determine_fetch_requirements(): [ticker_tracking] must be a single-row data.frame"
    )
  }
  if (!inherits(reference_date, "Date")) {
    stop(
      "determine_fetch_requirements(): [reference_date] must be a Date object"
    )
  }

  # Price and splits: always fetch on scheduled runs
  fetch_price <- TRUE
  fetch_splits <- TRUE

  # Quarterly: smart refresh based on earnings timing
  fetch_quarterly <- should_fetch_quarterly_data(
    next_estimated_report_date = ticker_tracking$next_estimated_report_date,
    quarterly_last_fetched_at = ticker_tracking$quarterly_last_fetched_at,
    reference_date = reference_date
  )

  list(
    price = fetch_price,
    splits = fetch_splits,
    quarterly = fetch_quarterly
  )
}
