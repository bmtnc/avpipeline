#' Fetch Company Overview
#'
#' Fetches company metadata (sector, industry, exchange, country) from Alpha
#' Vantage's OVERVIEW endpoint.
#'
#' @param ticker character: Stock ticker symbol
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @return tibble with one row of company metadata (see parse_overview_response)
#' @keywords internal
fetch_overview <- function(ticker, api_key = NULL) {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")

  response <- make_av_request(
    ticker = ticker,
    api_function = "OVERVIEW",
    api_key = api_key
  )

  parse_overview_response(response, ticker)
}
