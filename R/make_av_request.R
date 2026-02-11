#' Make Alpha Vantage API Request
#'
#' Makes HTTP requests to the Alpha Vantage API with retry logic.
#'
#' @param ticker character: Stock ticker symbol
#' @param api_function character: Alpha Vantage API function name
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @param ... Additional query parameters (outputsize, datatype, etc.)
#' @return httr2 response object
#' @keywords internal
make_av_request <- function(ticker, api_function, api_key = NULL, ...) {
  validate_character_scalar(ticker, name = "ticker")
  validate_character_scalar(api_function, name = "api_function")

  if (is.null(api_key)) {
    api_key <- get_api_key()
  }

  req <- build_av_request(ticker, api_function, api_key, ...)
  httr2::req_perform(req)
}
