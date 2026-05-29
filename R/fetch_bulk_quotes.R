#' Fetch Realtime Bulk Quotes
#'
#' Fetches current-day quotes for up to 100 symbols in a single API call via the
#' REALTIME_BULK_QUOTES endpoint. Returns raw (unadjusted) OHLCV.
#'
#' @param symbols character: Vector of ticker symbols (max 100 per call)
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @return tibble: one row per symbol (see parse_bulk_quotes_response())
#' @keywords internal
fetch_bulk_quotes <- function(symbols, api_key = NULL) {
  if (!is.character(symbols) || length(symbols) == 0) {
    stop("fetch_bulk_quotes(): [symbols] must be a non-empty character vector")
  }
  if (length(symbols) > 100) {
    stop("fetch_bulk_quotes(): REALTIME_BULK_QUOTES accepts at most 100 symbols per call")
  }

  response <- make_av_request(
    ticker = paste(symbols, collapse = ","),
    api_function = "REALTIME_BULK_QUOTES",
    api_key = api_key,
    datatype = "json"
  )

  parse_bulk_quotes_response(response)
}
