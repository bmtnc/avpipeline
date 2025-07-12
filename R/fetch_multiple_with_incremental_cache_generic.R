#' Generic Multiple Fetch with Incremental Caching
#'
#' Generic function that handles the incremental caching pattern used across different
#' data types (price, income statement, etc.). This function processes each ticker
#' individually and writes to cache immediately after each successful API call
#' to prevent data loss if the process is interrupted.
#'
#' @param tickers Character vector of ticker symbols to fetch
#' @param cache_file Path to cache file (CSV format)
#' @param single_fetch_func Function to fetch data for a single ticker
#' @param cache_reader_func Function to read cached data
#' @param data_type_name Character string for logging (e.g., "price", "income statement")
#' @param delay_seconds Numeric. Delay between API calls in seconds
#' @param as_of_date Date, timestamp for when data was pulled (defaults to current date)
#' @param ... Additional parameters passed to single_fetch_func
#'
#' @return Invisible NULL (data is written to cache file)
#'
#' @examples
#' \dontrun{
#' # For price data
#' fetch_multiple_with_incremental_cache_generic(
#'   tickers = c("AAPL", "GOOGL"),
#'   cache_file = "cache/price_data.csv",
#'   single_fetch_func = fetch_daily_adjusted_prices,
#'   cache_reader_func = read_cached_price_data,
#'   data_type_name = "price",
#'   delay_seconds = 1,
#'   outputsize = "full",
#'   datatype = "json"
#' )
#' 
#' # For income statement data
#' fetch_multiple_with_incremental_cache_generic(
#'   tickers = c("AAPL", "GOOGL"),
#'   cache_file = "cache/income_statement_data.csv",
#'   single_fetch_func = fetch_income_statement,
#'   cache_reader_func = read_cached_income_statement_data,
#'   data_type_name = "income statement",
#'   delay_seconds = 12
#' )
#' }
#'
#' @export
fetch_multiple_with_incremental_cache_generic <- function(tickers,
                                                          cache_file,
                                                          single_fetch_func,
                                                          cache_reader_func,
                                                          data_type_name = "data",
                                                          delay_seconds = 1,
                                                          as_of_date = Sys.Date(),
                                                          ...) {
  
  # Validate inputs
  if (length(tickers) == 0) {
    stop("No tickers provided")
  }
  
  if (missing(cache_file)) {
    stop("cache_file parameter is required")
  }
  
  if (missing(single_fetch_func)) {
    stop("single_fetch_func parameter is required")
  }
  
  if (missing(cache_reader_func)) {
    stop("cache_reader_func parameter is required")
  }
  
  # Initialize progress tracking
  total_tickers <- length(tickers)
  successful_fetches <- 0
  failed_fetches <- 0
  
  cat("Processing", total_tickers, "tickers for", data_type_name, "data with incremental caching...\n")
  
  # Process each ticker individually
  for (i in seq_along(tickers)) {
    ticker <- tickers[i]
    
    tryCatch({
      # Fetch data for current ticker
      cat("[", i, "/", total_tickers, "] Fetching", data_type_name, "data for symbol:", ticker, "\n")
      
      # Build arguments for single fetch function
      fetch_args <- list(...)
      
      # Both price and income statement functions now use 'ticker' parameter
      ticker_data <- single_fetch_func(ticker = ticker, ...)
      
      # Add as_of_date metadata
      if (nrow(ticker_data) > 0) {
        ticker_data$as_of_date <- as_of_date
      }
      
      # Write to cache immediately (append if file exists)
      if (file.exists(cache_file)) {
        # Read existing data
        existing_data <- cache_reader_func(cache_file)
        
        # Combine with new data
        combined_data <- dplyr::bind_rows(existing_data, ticker_data)
        
        # Remove duplicates based on appropriate columns
        if (grepl("income", data_type_name, ignore.case = TRUE)) {
          # For income statements, deduplicate on ticker and fiscalDateEnding
          combined_data <- combined_data %>%
            dplyr::distinct(ticker, fiscalDateEnding, .keep_all = TRUE)
        } else {
          # For price data, deduplicate on ticker and date
          combined_data <- combined_data %>%
            dplyr::distinct(ticker, date, .keep_all = TRUE)
        }
        
        # Write back to file
        write.csv(combined_data, cache_file, row.names = FALSE)
        
      } else {
        # Create new file
        write.csv(ticker_data, cache_file, row.names = FALSE)
      }
      
      successful_fetches <- successful_fetches + 1
      cat("✓ Data for", ticker, "saved to cache (", nrow(ticker_data), "rows)\n")
      
      # Add delay between requests (except for the last one)
      if (i < total_tickers && delay_seconds > 0) {
        Sys.sleep(delay_seconds)
      }
      
    }, error = function(e) {
      cat("✗ Error processing ticker", ticker, ":", e$message, "\n")
      failed_fetches <<- failed_fetches + 1
    })
  }
  
  # Report summary
  cat("Incremental caching complete!\n")
  cat("Successfully processed:", successful_fetches, "tickers\n")
  cat("Failed to process:", failed_fetches, "tickers\n")
  
  return(invisible(TRUE))
}
