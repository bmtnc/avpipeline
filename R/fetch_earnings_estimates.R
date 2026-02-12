#' Fetch Earnings Estimates Data
#'
#' Fetches EPS and revenue consensus estimates from Alpha Vantage.
#'
#' @param ticker character: Stock ticker symbol
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @return tibble with quarterly and annual earnings estimates
#' @keywords internal
fetch_earnings_estimates <- function(ticker, api_key = NULL) {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")

  response <- make_av_request(
    ticker = ticker,
    api_function = "EARNINGS_ESTIMATES",
    api_key = api_key
  )

  parse_earnings_estimates_response(response, ticker)
}
