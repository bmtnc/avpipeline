#' Fetch Historical Options Chain for One Date
#'
#' @param ticker character: Stock ticker symbol
#' @param date Date or character: Observation date (YYYY-MM-DD)
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @param datatype character: "json" or "csv"
#' @return tibble with option chain data
#' @keywords internal
fetch_historical_options <- function(ticker, date, api_key = NULL, datatype = "csv") {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")

  date_str <- format(as.Date(date), "%Y-%m-%d")

  response <- make_av_request(
    ticker = ticker,
    api_function = "HISTORICAL_OPTIONS",
    api_key = api_key,
    date = date_str,
    datatype = datatype
  )

  parse_historical_options_response(response, ticker, datatype)
}
