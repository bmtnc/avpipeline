#' Normalize Bulk Quotes to the Price Artifact Schema
#'
#' Maps a parsed REALTIME_BULK_QUOTES tibble onto the canonical daily price
#' schema so interim bars can be overlaid on authoritative history. The adjusted
#' fields are provisional: `adjusted_close` equals raw `close` and the corporate-
#' action fields are neutral until the weekly TIME_SERIES_DAILY_ADJUSTED run
#' re-derives them.
#'
#' @param bulk_quotes tibble from parse_bulk_quotes_response()
#' @return tibble with the price artifact columns (ticker, date, open, high, low,
#'   close, adjusted_close, volume, dividend_amount, split_coefficient)
#' @keywords internal
normalize_bulk_quotes_to_price_schema <- function(bulk_quotes) {
  validate_df_type(bulk_quotes)

  dplyr::transmute(
    bulk_quotes,
    ticker = ticker,
    date = date,
    open = open,
    high = high,
    low = low,
    close = close,
    adjusted_close = close,
    volume = volume,
    dividend_amount = 0,
    split_coefficient = 1
  )
}
