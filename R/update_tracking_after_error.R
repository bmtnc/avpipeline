#' Update Tracking After Error
#'
#' Updates tracking to record an error for a ticker.
#'
#' @param tracking tibble: Full refresh tracking dataframe
#' @param ticker character: Stock symbol
#' @param error_message character: Error message to record
#' @return tibble: Updated tracking dataframe
#' @keywords internal
update_tracking_after_error <- function(tracking, ticker, error_message) {
  if (!is.character(error_message) || length(error_message) != 1) {
    stop("update_tracking_after_error(): [error_message] must be a character scalar")
  }

  update_ticker_tracking(tracking, ticker, list(last_error_message = error_message))
}
