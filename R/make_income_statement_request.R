#' Make API request to Alpha Vantage for income statement data
#'
#' @param symbol Character. The equity symbol
#' @param api_key Character. Alpha Vantage API key
#'
#' @return Raw httr response object
#' @keywords internal
make_income_statement_request <- function(symbol, api_key) {
  # Get API key if not provided
  if (is.null(api_key)) {
    api_key <- get_api_key()
  }
  
  # Build API URL
  base_url <- "https://www.alphavantage.co/query"
  
  # Set up query parameters
  query_params <- list(
    `function` = "INCOME_STATEMENT",
    symbol = symbol,
    apikey = api_key
  )
  
  # Make API request
  cat("Fetching income statement data for symbol:", symbol, "\n")
  
  response <- httr::GET(
    url = base_url,
    query = query_params
  )
  
  # Check if request was successful
  if (httr::status_code(response) != 200) {
    stop("API request failed with status code: ", httr::status_code(response))
  }
  
  return(response)
}
