#' Fetch Stock Split History
#'
#' Fetches stock split history from Alpha Vantage.
#'
#' @param ticker character: Stock ticker symbol
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @return data.frame with split events
#' @keywords internal
fetch_splits <- function(ticker, api_key = NULL) {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")

  response <- make_av_request(
    ticker = ticker,
    api_function = "SPLITS",
    api_key = api_key
  )

  parse_splits_response(response, ticker)
}
