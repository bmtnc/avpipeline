#' Fetch Quarterly Income Statement Data
#'
#' Fetches quarterly income statement data from Alpha Vantage.
#'
#' @param ticker character: Stock ticker symbol
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @return tibble with quarterly income statement data
#' @keywords internal
fetch_income_statement <- function(ticker, api_key = NULL) {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")

  response <- make_av_request(
    ticker = ticker,
    api_function = "INCOME_STATEMENT",
    api_key = api_key
  )

  parse_income_statement_response(response, ticker)
}
