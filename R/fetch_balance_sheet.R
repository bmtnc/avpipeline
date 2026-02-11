#' Fetch Quarterly Balance Sheet Data
#'
#' Fetches quarterly balance sheet data from Alpha Vantage.
#'
#' @param ticker character: Stock ticker symbol
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @return tibble with quarterly balance sheet data
#' @keywords internal
fetch_balance_sheet <- function(ticker, api_key = NULL) {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")

  response <- make_av_request(
    ticker = ticker,
    api_function = "BALANCE_SHEET",
    api_key = api_key
  )

  parse_balance_sheet_response(response, ticker)
}
