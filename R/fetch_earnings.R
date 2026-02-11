#' Fetch Quarterly Earnings Timing Data
#'
#' Fetches quarterly earnings timing data from Alpha Vantage.
#'
#' @param ticker character: Stock ticker symbol
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @return tibble with quarterly earnings timing data
#' @keywords internal
fetch_earnings <- function(ticker, api_key = NULL) {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")

  response <- make_av_request(
    ticker = ticker,
    api_function = "EARNINGS",
    api_key = api_key
  )

  parse_earnings_response(response, ticker)
}
