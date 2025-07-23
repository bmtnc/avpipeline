#' Multiple Ticker Data Fetcher
#'
#' Fetches data from Alpha Vantage API for multiple tickers using configuration
#' objects. This function replaces all individual multiple-ticker fetch functions
#' by using a unified approach with progress tracking and error handling.
#'
#' @param tickers Character vector. Vector of equity symbols
#' @param config List. Configuration object defining the data type and processing parameters
#' @param api_key Character. Alpha Vantage API key. If NULL, will use get_api_key()
#' @param delay_seconds Numeric. Delay between API calls in seconds. If NULL, uses config default
#' @param ... Additional parameters passed to the API (e.g., outputsize, datatype)
#'
#' @return A tibble with data for all tickers in long format
#' @export
#'
fetch_multiple_ticker_data <- function(tickers, config, api_key = NULL, delay_seconds = NULL, ...) {
  
  # Step 1: Validate inputs
  if (missing(tickers) || !is.character(tickers) || length(tickers) == 0) {
    stop("tickers must be a non-empty character vector")
  }
  
  if (missing(config) || !is.list(config)) {
    stop("config must be a configuration list object")
  }
  
  # Use config default delay if not provided
  if (is.null(delay_seconds)) {
    delay_seconds <- config$default_delay %||% 1
  }
  
  if (!is.numeric(delay_seconds) || delay_seconds < 0) {
    stop("delay_seconds must be a non-negative number")
  }
  
  # Step 2: Get API key once
  if (is.null(api_key)) {
    api_key <- get_api_key()
  }
  
  # Step 3: Process all tickers with progress tracking
  results_list <- fetch_tickers_with_progress(
    tickers = tickers,
    config = config,
    api_key = api_key,
    delay_seconds = delay_seconds,
    ...
  )
  
  # Step 4: Combine and process results
  combined_data <- combine_ticker_results(results_list, tickers, config)
  
  return(combined_data)
}

# Utility function for default values
`%||%` <- function(x, y) if (is.null(x)) y else x
