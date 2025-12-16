#' Get Tracking for a Single Ticker
#'
#' Retrieves tracking row for a ticker, or creates default if not found.
#'
#' @param ticker character: Stock symbol
#' @param tracking tibble: Full refresh tracking dataframe
#' @return tibble: Single row for the ticker
#' @keywords internal
get_ticker_tracking <- function(ticker, tracking) {
  validate_character_scalar(ticker, name = "ticker")
  validate_df_type(tracking)

  ticker_row <- dplyr::filter(tracking, ticker == !!ticker)

  if (nrow(ticker_row) == 0) {
    return(create_default_ticker_tracking(ticker))
  }

  ticker_row
}
