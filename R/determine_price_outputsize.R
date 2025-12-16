#' Determine Price Outputsize (Compact vs Full)
#'
#' Decides whether to fetch compact (100 days) or full (20+ years) price history.
#' Uses compact when: has full history AND <90 days stale.
#'
#' @param price_has_full_history logical: Whether we have full history for this ticker
#' @param price_last_date Date: Most recent date in our price data (can be NA)
#' @param reference_date Date: Current date (default: Sys.Date())
#' @return character: "compact" or "full"
#' @keywords internal
determine_price_outputsize <- function(
  price_has_full_history,
  price_last_date,
  reference_date = Sys.Date()
) {
  if (!is.logical(price_has_full_history) || length(price_has_full_history) != 1) {
    stop("determine_price_outputsize(): [price_has_full_history] must be a logical scalar")
  }
  if (!inherits(reference_date, "Date")) {
    stop("determine_price_outputsize(): [reference_date] must be a Date object")
  }

  if (!isTRUE(price_has_full_history)) {
    return("full")
  }

  if (is.na(price_last_date)) {
    return("full")
  }

  days_stale <- as.numeric(difftime(reference_date, price_last_date, units = "days"))

  if (days_stale > 90) {
    return("full")
  }

  "compact"
}
