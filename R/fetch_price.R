#' Fetch Daily Adjusted Price Data
#'
#' Fetches daily adjusted price data from Alpha Vantage.
#'
#' @param ticker character: Stock ticker symbol
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @param outputsize character: "compact" (100 days) or "full" (20+ years)
#' @param datatype character: "json" or "csv"
#' @return tibble with daily price data
#' @keywords internal
fetch_price <- function(ticker, api_key = NULL, outputsize = "compact", datatype = "json") {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")

  response <- make_av_request(
    ticker = ticker,
    api_function = "TIME_SERIES_DAILY_ADJUSTED",
    api_key = api_key,
    outputsize = outputsize,
    datatype = datatype
  )

  parse_price_response(response, ticker, datatype)
}
