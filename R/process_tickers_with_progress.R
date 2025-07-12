#' Process all tickers with progress tracking and error handling
#'
#' @param tickers Character vector. Vector of equity symbols
#' @param outputsize Character. Either "compact" or "full"
#' @param datatype Character. Either "json" or "csv"
#' @param api_key Character. Alpha Vantage API key
#' @param delay_seconds Numeric. Delay between API calls in seconds
#'
#' @return List of tibbles with ticker data (NULL entries for failed fetches)
#' @keywords internal
process_tickers_with_progress <- function(tickers, outputsize, datatype, api_key, delay_seconds) {
  cat("Fetching data for", length(tickers), "tickers...\n")
  
  # Initialize list to store results
  results_list <- list()
  
  # Fetch data for each ticker
  for (i in seq_along(tickers)) {
    ticker <- tickers[i]
    
    cat(paste0("[", i, "/", length(tickers), "] "))
    
    # Try to fetch data for this ticker
    tryCatch({
      ticker_data <- fetch_daily_adjusted_prices(
        symbol = ticker,
        outputsize = outputsize,
        datatype = datatype,
        api_key = api_key
      )
      
      results_list[[ticker]] <- ticker_data
      
      # Add delay between requests (except for the last one)
      if (i < length(tickers) && delay_seconds > 0) {
        Sys.sleep(delay_seconds)
      }
      
    }, error = function(e) {
      warning("Failed to fetch data for ", ticker, ": ", e$message)
      results_list[[ticker]] <- NULL
    })
  }
  
  return(results_list)
}
