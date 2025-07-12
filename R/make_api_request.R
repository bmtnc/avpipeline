#' Make API request to Alpha Vantage for daily adjusted price data
#'
#' @param symbol Character. The equity symbol
#' @param outputsize Character. Either "compact" or "full"
#' @param datatype Character. Either "json" or "csv"
#' @param api_key Character. Alpha Vantage API key
#'
#' @return Raw httr response object
#' @keywords internal
make_api_request <- function(symbol, outputsize, datatype, api_key) {
  # Get API key if not provided
  if (is.null(api_key)) {
    api_key <- get_api_key()
  }
  
  # Build API URL
  base_url <- "https://www.alphavantage.co/query"
  
  # Set up query parameters
  query_params <- list(
    `function` = "TIME_SERIES_DAILY_ADJUSTED",
    symbol = symbol,
    outputsize = outputsize,
    datatype = datatype,
    apikey = api_key
  )
  
  # Make API request
  cat("Fetching data for symbol:", symbol, "\n")
  
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
