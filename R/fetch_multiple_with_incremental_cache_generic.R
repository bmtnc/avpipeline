#' Generic Multiple Fetch with Batch Caching
#'
#' Generic function that handles the batch caching pattern used across different
#' data types (price, income statement, etc.). This function processes each ticker
#' individually, collects all successful results in memory, and writes all data
#' to cache at once at the end.
#'
#' @param tickers Character vector of ticker symbols to fetch
#' @param cache_file Path to cache file (CSV format)
#' @param single_fetch_func Function to fetch data for a single ticker
#' @param cache_reader_func Function to read cached data
#' @param data_type_name Character string for logging (e.g., "price", "income statement")
#' @param delay_seconds Numeric. Delay between API calls in seconds
#' @param max_retries Numeric. Maximum number of retry attempts per ticker (default 3)
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
#'   max_retries = 3,
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
#'   delay_seconds = 12,
#'   max_retries = 3
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
                                                          max_retries = 3,
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
  successful_results <- list()
  failed_tickers <- list()
  
  cat("Processing", total_tickers, "tickers for", data_type_name, "data with batch caching...\n")
  
  # Process each ticker individually
  for (i in seq_along(tickers)) {
    ticker <- tickers[i]
    ticker_data <- NULL
    success <- FALSE
    
    cat("[", i, "/", total_tickers, "] Fetching", data_type_name, "data for symbol:", ticker, "\n")
    
    # Try API call with retry logic
    for (attempt in 1:max_retries) {
      tryCatch({
        # Fetch data for current ticker
        ticker_data <- single_fetch_func(ticker = ticker, ...)
        
        # Add as_of_date metadata
        if (nrow(ticker_data) > 0) {
          ticker_data$as_of_date <- as_of_date
        }
        
        # Success - break out of retry loop
        success <- TRUE
        break
        
      }, error = function(e) {
        if (attempt < max_retries) {
          # Calculate retry delay (5 seconds for first retry, 10 for second)
          retry_delay <- if (attempt == 1) 5 else 10
          cat("  Attempt", attempt, "failed for", ticker, "- waiting", retry_delay, "seconds before retry\n")
          Sys.sleep(retry_delay)
        } else {
          # Final failure after all retries
          cat("  All", max_retries, "attempts failed for", ticker, ":", e$message, "\n")
          failed_tickers[[ticker]] <<- e$message
        }
      })
    }
    
    # If successful, add to results
    if (success) {
      successful_results[[ticker]] <- ticker_data
      cat("Success: Data for", ticker, "collected (", nrow(ticker_data), "rows)\n")
    }
    
    # Add delay between requests (except for the last one)
    if (i < total_tickers && delay_seconds > 0) {
      Sys.sleep(delay_seconds)
    }
  }
  
  # Process results
  successful_count <- length(successful_results)
  failed_count <- length(failed_tickers)
  
  cat("\n=== API Fetch Complete ===\n")
  cat("Successfully fetched:", successful_count, "tickers\n")
  cat("Failed to fetch:", failed_count, "tickers\n")
  
  # Report failed tickers
  if (failed_count > 0) {
    cat("\nFailed tickers:\n")
    for (ticker in names(failed_tickers)) {
      cat("  -", ticker, ":", failed_tickers[[ticker]], "\n")
    }
  }
  
  # Combine successful results and write to cache
  if (successful_count > 0) {
    cat("\nCombining and writing", successful_count, "successful results to cache...\n")
    
    # Combine all successful results
    new_data <- dplyr::bind_rows(successful_results)
    
    # Read existing cache data if it exists
    if (file.exists(cache_file)) {
      existing_data <- cache_reader_func(cache_file)
      combined_data <- dplyr::bind_rows(existing_data, new_data)
    } else {
      combined_data <- new_data
    }
    
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
    
    # Write combined data to cache
    write.csv(combined_data, cache_file, row.names = FALSE)
    
    cat("Success: All data written to cache:", cache_file, "\n")
    cat("Total rows in cache:", nrow(combined_data), "\n")
    
  } else {
    cat("No successful data to write to cache.\n")
  }
  
  # Final summary
  cat("\n=== Batch Caching Complete ===\n")
  cat("Successfully processed:", successful_count, "tickers\n")
  cat("Failed to process:", failed_count, "tickers\n")
  
  return(invisible(TRUE))
}
