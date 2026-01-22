#' Determine Fetch Requirements for a Ticker
#'
#' Determines which data types need to be fetched for a ticker based on tracking state.
#'
#' @param ticker_tracking tibble: Single row from refresh tracking for this ticker
#' @param reference_date Date: Date to check against (defaults to today)
#' @param fetch_mode character: "full" (default), "price_only", or "quarterly_only"
#' @return list: Named list with price, splits, quarterly (each TRUE/FALSE)
#' @keywords internal
determine_fetch_requirements <- function(
  ticker_tracking,
  reference_date = Sys.Date(),
  fetch_mode = "full"
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
  if (!fetch_mode %in% c("full", "price_only", "quarterly_only")) {
    stop(
      "determine_fetch_requirements(): [fetch_mode] must be 'full', 'price_only', or 'quarterly_only'"
    )
  }

  if (fetch_mode == "price_only") {
    return(list(
      price = TRUE,
      splits = FALSE,
      quarterly = FALSE
    ))
  }

  if (fetch_mode == "quarterly_only") {
    return(list(
      price = FALSE,
      splits = FALSE,
      quarterly = TRUE
    ))
  }

  fetch_price <- TRUE
  fetch_splits <- TRUE

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
