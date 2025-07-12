#' Fetch Multiple Income Statements with Incremental Caching
#'
#' Fetches quarterly income statement data for multiple tickers with incremental caching
#' that writes each ticker's data to the cache file immediately after successful API call.
#' This prevents data loss if the process is interrupted.
#'
#' @param tickers Character vector of ticker symbols to fetch
#' @param cache_file Path to cache file (CSV format)
#' @param as_of_date Date, timestamp for when data was pulled (defaults to current date)
#'
#' @return Invisibly returns TRUE on completion
#'
#' @examples
#' \dontrun{
#' tickers <- c("AAPL", "GOOGL", "MSFT")
#' fetch_multiple_income_statements_with_incremental_cache(
#'   tickers = tickers,
#'   cache_file = "cache/income_statement_data.csv"
#' )
#' }
#'
#' @export
fetch_multiple_income_statements_with_incremental_cache <- function(tickers, 
                                                                    cache_file,
                                                                    as_of_date = Sys.Date()) {
  
  # Validate inputs
  if (length(tickers) == 0) {
    stop("No tickers provided")
  }
  
  if (missing(cache_file)) {
    stop("cache_file parameter is required")
  }
  
  # Initialize progress tracking
  total_tickers <- length(tickers)
  successful_fetches <- 0
  failed_fetches <- 0
  
  cat("Processing", total_tickers, "tickers for income statement data with incremental caching...\n")
  
  # Process each ticker individually
  for (i in seq_along(tickers)) {
    ticker <- tickers[i]
    
    tryCatch({
      # Fetch income statement data for current ticker
      cat("[", i, "/", total_tickers, "] Fetching income statement data for symbol:", ticker, "\n")
      
      # Fetch data
      ticker_data <- fetch_income_statement(ticker)
      
      # Add as_of_date metadata
      if (nrow(ticker_data) > 0) {
        ticker_data$as_of_date <- as_of_date
      }
      
      # Write to cache immediately (append if file exists)
      if (file.exists(cache_file)) {
        # Read existing data
        existing_data <- read_cached_income_statement_data(cache_file)
        
        # Combine with new data
        combined_data <- dplyr::bind_rows(existing_data, ticker_data)
        
        # Remove duplicates based on ticker and fiscalDateEnding
        combined_data <- combined_data %>%
          dplyr::distinct(ticker, fiscalDateEnding, .keep_all = TRUE)
        
        # Write back to file
        write.csv(combined_data, cache_file, row.names = FALSE)
        
      } else {
        # Create new file
        write.csv(ticker_data, cache_file, row.names = FALSE)
      }
      
      successful_fetches <- successful_fetches + 1
      cat("✓ Data for", ticker, "saved to cache (", nrow(ticker_data), "rows)\n")
      
      # Rate limiting: sleep for 12 seconds between requests (5 requests per minute limit)
      if (i < total_tickers) {
        Sys.sleep(12)
      }
      
    }, error = function(e) {
      cat("Error processing ticker", ticker, ":", e$message, "\n")
      failed_fetches <<- failed_fetches + 1
    })
  }
  
  # Report summary
  cat("Incremental caching complete!\n")
  cat("Successfully processed:", successful_fetches, "tickers\n")
  cat("Failed to process:", failed_fetches, "tickers\n")
  
  return(invisible(TRUE))
}
