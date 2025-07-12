#' Fetch Multiple Tickers with Incremental Caching
#'
#' Fetches daily adjusted price data for multiple tickers with incremental caching.
#' After each successful API call, the data is immediately written to the cache file.
#' This prevents data loss if the process is interrupted partway through.
#'
#' @param tickers Character vector of ticker symbols to fetch
#' @param cache_file Path to cache file (CSV format)
#' @param outputsize Character, either "compact" (latest 100 days) or "full" (20+ years)
#' @param datatype Character, data format ("json" or "csv")
#' @param as_of_date Date, timestamp for when data was pulled (defaults to current date)
#' @param api_key Character. Alpha Vantage API key. If NULL, will use get_api_key() function.
#' @param delay_seconds Numeric. Delay between API calls in seconds. Default is 1
#'
#' @return Invisible NULL (data is written to cache file)
#' @keywords internal
fetch_multiple_tickers_with_incremental_cache <- function(tickers,
                                                          cache_file,
                                                          outputsize = "full",
                                                          datatype = "json",
                                                          as_of_date = Sys.Date(),
                                                          api_key = NULL,
                                                          delay_seconds = 1) {
  
  # Get API key once
  if (is.null(api_key)) {
    api_key <- get_api_key()
  }
  
  # Process each ticker individually
  for (i in seq_along(tickers)) {
    ticker <- tickers[i]
    
    cat(paste0("[", i, "/", length(tickers), "] "))
    
    # Try to fetch data for this ticker
    tryCatch({
      # Fetch data for single ticker
      ticker_data <- fetch_daily_adjusted_prices(
        symbol = ticker,
        outputsize = outputsize,
        datatype = datatype,
        api_key = api_key
      )
      
      # Add as_of_date column
      ticker_data$as_of_date <- as_of_date
      
      # Read existing cache data if file exists
      if (file.exists(cache_file)) {
        existing_data <- read_cached_price_data(cache_file)
        
        # Combine with new data
        combined_data <- dplyr::bind_rows(existing_data, ticker_data)
      } else {
        # First ticker - no existing data
        combined_data <- ticker_data
      }
      
      # Write combined data back to cache file
      write.csv(combined_data, cache_file, row.names = FALSE)
      
      cat("✓ Data for", ticker, "saved to cache (", nrow(ticker_data), "rows)\n")
      
      # Add delay between requests (except for the last one)
      if (i < length(tickers) && delay_seconds > 0) {
        Sys.sleep(delay_seconds)
      }
      
    }, error = function(e) {
      cat("✗ Failed to fetch data for", ticker, ":", e$message, "\n")
      warning("Failed to fetch data for ", ticker, ": ", e$message)
    })
  }
  
  invisible(NULL)
}
