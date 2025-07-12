#' Fetch Income Statement Data from Alpha Vantage
#'
#' Fetches quarterly income statement data for a specified equity symbol using 
#' the Alpha Vantage API. Returns only quarterly data to avoid mixing annual 
#' and quarterly numbers in time series analysis.
#'
#' @param symbol Character. The equity symbol (e.g., "IBM", "AAPL")
#' @param api_key Character. Alpha Vantage API key. If NULL, will use 
#'   get_api_key() function.
#'
#' @return A tibble with quarterly income statement data
#' @export
fetch_income_statement <- function(symbol, api_key = NULL) {
  
  # Step 1: Validate inputs
  if (missing(symbol) || !is.character(symbol) || length(symbol) != 1) {
    stop("symbol must be a single character string")
  }
  
  # Step 2: Make API request
  response <- make_income_statement_request(symbol, api_key)
  
  # Step 3: Parse response to tibble
  parse_income_statement_response(response, symbol)
}
