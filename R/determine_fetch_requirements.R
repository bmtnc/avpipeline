#' Determine Fetch Requirements for a Ticker
#'
#' Determines which data types need to be fetched for a ticker based on tracking state.
#'
#' @param ticker_tracking tibble: Single row from refresh tracking for this ticker
#' @param reference_date Date: Date to check against (defaults to today)
#' @param fetch_mode character: "full" (default), "price_only", or "quarterly_only"
#' @param overview_exists logical: Whether overview is already stored in S3 for
#'   this ticker. Overview is a gap-fill: fetched once when missing, never
#'   re-pulled. Defaults to TRUE (assume present) so callers that don't track
#'   overview presence never trigger a fetch.
#' @return list: Named list with price, splits, overview, quarterly (each TRUE/FALSE)
#' @keywords internal
determine_fetch_requirements <- function(
  ticker_tracking,
  reference_date = Sys.Date(),
  fetch_mode = "full",
  overview_exists = TRUE
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

  # Overview is fetched only when missing from S3, and never on price-only runs.
  overview_required <- fetch_mode != "price_only" && !isTRUE(overview_exists)

  if (fetch_mode == "price_only") {
    return(list(
      price = TRUE,
      splits = FALSE,
      overview = FALSE,
      quarterly = FALSE
    ))
  }

  # Quarterly is gated by the smart-refresh check in every mode that fetches it,
  # so the daily quarterly_only run only pulls tickers near earnings or stale —
  # not all of them.
  fetch_quarterly <- should_fetch_quarterly_data(
    next_estimated_report_date = ticker_tracking$next_estimated_report_date,
    quarterly_last_fetched_at = ticker_tracking$quarterly_last_fetched_at,
    reference_date = reference_date,
    statements_lag_earnings = ticker_tracking$has_data_discrepancy,
    last_reported_date = ticker_tracking$last_reported_date
  )

  if (fetch_mode == "quarterly_only") {
    return(list(
      price = FALSE,
      splits = FALSE,
      overview = overview_required,
      quarterly = fetch_quarterly
    ))
  }

  list(
    price = TRUE,
    splits = TRUE,
    overview = overview_required,
    quarterly = fetch_quarterly
  )
}
