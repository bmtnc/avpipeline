#' Fetch Income Statement Data from Alpha Vantage
#'
#' Fetches quarterly income statement data for a specified equity ticker using 
#' the Alpha Vantage API. Returns only quarterly data to avoid mixing annual 
#' and quarterly numbers in time series analysis.
#'
#' @param ticker Character. The equity ticker (e.g., "IBM", "AAPL")
#' @param api_key Character. Alpha Vantage API key. If NULL, will use 
#'   get_api_key() function.
#'
#' @return A tibble with quarterly income statement data
#' @export
fetch_income_statement <- function(ticker, api_key = NULL) {
  
  # Step 1: Validate inputs
  if (missing(ticker) || !is.character(ticker) || length(ticker) != 1) {
    stop("ticker must be a single character string")
  }
  
  # Step 2: Make API request
  response <- make_income_statement_request(ticker, api_key)
  
  # Step 3: Parse response to tibble
  parse_income_statement_response(response, ticker)
}
