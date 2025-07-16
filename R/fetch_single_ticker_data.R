#' Single Ticker Data Fetcher
#'
#' Fetches data from Alpha Vantage API for any supported data type using
#' configuration objects. This function replaces all individual single-ticker
#' fetch functions by using a unified approach.
#'
#' @param ticker Character. The equity ticker symbol
#' @param config List. Configuration object defining the API function and parsing
#' @param api_key Character. Alpha Vantage API key. If NULL, will use get_api_key()
#' @param ... Additional parameters passed to the API (e.g., outputsize, datatype)
#'
#' @return A tibble with the requested data type
#' @export
#' 
#' @examples
#' \dontrun{
#' # Fetch price data
#' price_data <- fetch_single_ticker_data("AAPL", PRICE_CONFIG, outputsize = "full")
#' 
#' # Fetch income statement data
#' income_data <- fetch_single_ticker_data("AAPL", INCOME_STATEMENT_CONFIG)
#' 
#' # Fetch balance sheet data
#' balance_data <- fetch_single_ticker_data("AAPL", BALANCE_SHEET_CONFIG)
#' 
#' # Fetch cash flow data
#' cash_flow_data <- fetch_single_ticker_data("AAPL", CASH_FLOW_CONFIG)
#' }
fetch_single_ticker_data <- function(ticker, config, api_key = NULL, ...) {
  
  # Validate inputs
  if (missing(ticker) || !is.character(ticker) || length(ticker) != 1) {
    stop("ticker must be a single character string")
  }
  
  if (missing(config) || !is.list(config)) {
    stop("config must be a configuration list object")
  }
  
  if (!"parser_func" %in% names(config)) {
    stop("config must contain a 'parser_func' element")
  }
  
  # Step 1: Make API request
  response <- make_alpha_vantage_request(ticker, config, api_key, ...)
  
  # Step 2: Parse response using config-specified parser
  parser_func_name <- config$parser_func
  parser_func <- get(parser_func_name)
  
  # Handle different parser function signatures
  if (config$api_function == "TIME_SERIES_DAILY_ADJUSTED") {
    # Price data parser needs datatype parameter
    additional_params <- list(...)
    datatype <- if ("datatype" %in% names(additional_params)) {
      additional_params$datatype
    } else {
      config$default_datatype %||% "json"
    }
    parsed_data <- parser_func(response, ticker, datatype)
  } else {
    # Other parsers just need response and ticker
    parsed_data <- parser_func(response, ticker)
  }
  
  return(parsed_data)
}

# Utility function for default values
`%||%` <- function(x, y) if (is.null(x)) y else x
