#' Process Income Statements with Progress Tracking
#'
#' Processes income statement data for multiple tickers with progress tracking,
#' error handling, and rate limiting for Alpha Vantage API calls.
#'
#' @param tickers Character vector. Vector of equity symbols
#' @param api_key Character. Alpha Vantage API key
#' @param delay_seconds Numeric. Delay between API calls in seconds
#'
#' @return List of tibbles containing income statement data for each ticker
#' @keywords internal
process_income_statements_with_progress <- function(tickers, api_key, delay_seconds) {
  cat("Fetching income statement data for", length(tickers), "tickers...\n")
  
  # Initialize list to store results
  results_list <- list()
  
  # Fetch data for each ticker
  for (i in seq_along(tickers)) {
    ticker <- tickers[i]
    
    cat(paste0("[", i, "/", length(tickers), "] "))
    
    # Try to fetch data for this ticker
    tryCatch({
      ticker_data <- fetch_income_statement(
        symbol = ticker,
        api_key = api_key
      )
      
      results_list[[ticker]] <- ticker_data
      
      # Add delay between requests (except for the last one)
      if (i < length(tickers) && delay_seconds > 0) {
        Sys.sleep(delay_seconds)
      }
      
    }, error = function(e) {
      warning("Failed to fetch income statement data for ", ticker, ": ", e$message)
      results_list[[ticker]] <- NULL
    })
  }
  
  return(results_list)
}
