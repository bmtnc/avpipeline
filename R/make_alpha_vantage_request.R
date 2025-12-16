#' Generic Alpha Vantage API Request Function
#'
#' Makes HTTP requests to the Alpha Vantage API for any supported data type.
#' This function replaces all individual API request functions by using
#' configuration objects to determine the appropriate parameters.
#'
#' @param ticker Character. The equity ticker symbol
#' @param config List. Configuration object defining the API function and parameters
#' @param api_key Character. Alpha Vantage API key. If NULL, will use get_api_key()
#' @param ... Additional parameters passed to the API (e.g., outputsize, datatype)
#'
#' @return Raw httr response object
#' @keywords internal
#' @export
#'
make_alpha_vantage_request <- function(ticker, config, api_key = NULL, ...) {
  if (missing(ticker)) {
    stop("ticker must be a single character string")
  }
  validate_character_scalar(ticker, name = "ticker")
  if (missing(config) || !is.list(config)) {
    stop("config must be a configuration list object")
  }
  if (!"api_function" %in% names(config)) {
    stop("config must contain an 'api_function' element")
  }
  if (!"data_type_name" %in% names(config)) {
    stop("config must contain a 'data_type_name' element")
  }

  # Get API key if not provided
  if (is.null(api_key)) {
    api_key <- get_api_key()
  }

  # Build API URL
  base_url <- "https://www.alphavantage.co/query"

  # Set up base query parameters
  query_params <- list(
    `function` = config$api_function,
    symbol = ticker,
    apikey = api_key
  )

  # Add additional parameters from function call
  additional_params <- list(...)
  if (length(additional_params) > 0) {
    query_params <- c(query_params, additional_params)
  }

  # Make API request
  cat("Fetching", config$data_type_name, "data for ticker:", ticker, "\n")

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
