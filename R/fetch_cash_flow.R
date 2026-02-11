#' Fetch Quarterly Cash Flow Data
#'
#' Fetches quarterly cash flow data from Alpha Vantage.
#'
#' @param ticker character: Stock ticker symbol
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @return tibble with quarterly cash flow data
#' @keywords internal
fetch_cash_flow <- function(ticker, api_key = NULL) {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")

  response <- make_av_request(
    ticker = ticker,
    api_function = "CASH_FLOW",
    api_key = api_key
  )

  parse_cash_flow_response(response, ticker)
}
