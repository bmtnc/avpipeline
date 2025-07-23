#' Fetch Tickers with Progress
#'
#' Processes multiple tickers with progress tracking, error handling, and rate limiting.
#' This function replaces all individual progress processing functions by using
#' configuration objects to determine the appropriate parameters and delays.
#'
#' @param tickers Character vector. Vector of equity symbols
#' @param config List. Configuration object defining the data type and processing parameters
#' @param api_key Character. Alpha Vantage API key
#' @param delay_seconds Numeric. Delay between API calls in seconds. If NULL, uses config default
#' @param ... Additional parameters passed to the single fetch function
#'
#' @return List of tibbles containing data for each ticker (NULL entries for failed fetches)
#' @keywords internal
#' @export
#'
fetch_tickers_with_progress <- function(tickers, config, api_key = NULL, delay_seconds = NULL, ...) {
  
  # Validate inputs
  if (missing(tickers) || !is.character(tickers) || length(tickers) == 0) {
    stop("tickers must be a non-empty character vector")
  }
  
  if (missing(config) || !is.list(config)) {
    stop("config must be a configuration list object")
  }
  
  if (!"data_type_name" %in% names(config)) {
    stop("config must contain a 'data_type_name' element")
  }
  
  # Use config default delay if not provided
  if (is.null(delay_seconds)) {
    delay_seconds <- config$default_delay %||% 1
  }
  
  if (!is.numeric(delay_seconds) || delay_seconds < 0) {
    stop("delay_seconds must be a non-negative number")
  }
  
  # Get API key once
  if (is.null(api_key)) {
    api_key <- get_api_key()
  }
  
  cat("Fetching", config$data_type_name, "data for", length(tickers), "tickers...\n")
  
  # Initialize list to store results
  results_list <- list()
  
  # Fetch data for each ticker
  for (i in seq_along(tickers)) {
    ticker <- tickers[i]
    
    cat(paste0("[", i, "/", length(tickers), "] "))
    
    # Try to fetch data for this ticker
    tryCatch({
      ticker_data <- fetch_single_ticker_data(
        ticker = ticker,
        config = config,
        api_key = api_key,
        ...
      )
      
      results_list[[ticker]] <- ticker_data
      
      # Add delay between requests (except for the last one)
      if (i < length(tickers) && delay_seconds > 0) {
        Sys.sleep(delay_seconds)
      }
      
    }, error = function(e) {
      warning("Failed to fetch ", config$data_type_name, " data for ", ticker, ": ", e$message)
      results_list[[ticker]] <- NULL
    })
  }
  
  return(results_list)
}

# Utility function for default values
`%||%` <- function(x, y) if (is.null(x)) y else x
