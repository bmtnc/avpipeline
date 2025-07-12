#' Generic Multiple Fetch with Caching
#'
#' Generic function that handles the caching orchestration pattern used across different
#' data types (price, income statement, etc.). This function provides intelligent caching
#' to avoid redundant API calls by checking cache files and only fetching missing data.
#'
#' @param tickers Character vector of ticker symbols to fetch
#' @param cache_file Path to cache file (CSV format)
#' @param cache_reader_func Function to read cached data (e.g., read_cached_price_data)
#' @param incremental_cache_func Function to perform incremental caching (e.g., fetch_multiple_tickers_with_incremental_cache)
#' @param data_type_name Character string for logging (e.g., "price", "income statement")
#' @param ... Additional parameters passed to incremental_cache_func
#'
#' @return A tibble with data for all requested tickers
#'
#' @examples
#' \dontrun{
#' # For price data
#' price_data <- fetch_multiple_with_cache_generic(
#'   tickers = c("AAPL", "GOOGL"),
#'   cache_file = "cache/price_data.csv",
#'   cache_reader_func = read_cached_price_data,
#'   incremental_cache_func = fetch_multiple_tickers_with_incremental_cache,
#'   data_type_name = "price",
#'   outputsize = "full",
#'   datatype = "json"
#' )
#' 
#' # For income statement data
#' income_data <- fetch_multiple_with_cache_generic(
#'   tickers = c("AAPL", "GOOGL"),
#'   cache_file = "cache/income_statement_data.csv",
#'   cache_reader_func = read_cached_income_statement_data,
#'   incremental_cache_func = fetch_multiple_income_statements_with_incremental_cache,
#'   data_type_name = "income statement"
#' )
#' }
#'
#' @export
fetch_multiple_with_cache_generic <- function(tickers, 
                                              cache_file,
                                              cache_reader_func,
                                              incremental_cache_func,
                                              data_type_name = "data",
                                              ...) {
  
  # Validate inputs
  if (length(tickers) == 0) {
    stop("No tickers provided")
  }
  
  if (missing(cache_file)) {
    stop("cache_file parameter is required")
  }
  
  if (missing(cache_reader_func)) {
    stop("cache_reader_func parameter is required")
  }
  
  if (missing(incremental_cache_func)) {
    stop("incremental_cache_func parameter is required")
  }
  
  # Initialize variables
  existing_data <- NULL
  tickers_to_fetch <- tickers
  
  # Check if cache file exists and process accordingly
  if (file.exists(cache_file)) {
    cat("Cache file found. Reading existing", data_type_name, "data...\n")
    
    # Read existing cached data using provided function
    existing_data <- cache_reader_func(cache_file)
    
    # Get tickers that need to be fetched
    tickers_to_fetch <- get_symbols_to_fetch(tickers, existing_data)
    
    # Get distinct tickers from existing data for reporting
    cached_tickers <- existing_data %>% 
      dplyr::distinct(ticker) %>% 
      dplyr::pull(ticker)
    
    cat("Tickers in cache:", paste(cached_tickers, collapse = ", "), "\n")
    cat("Tickers to fetch:", paste(tickers_to_fetch, collapse = ", "), "\n")
    
  } else {
    cat("No cache file found. Will fetch", data_type_name, "data for all tickers.\n")
  }
  
  # Fetch data only for tickers not in cache
  if (length(tickers_to_fetch) > 0) {
    cat("Fetching", data_type_name, "data from Alpha Vantage for", length(tickers_to_fetch), "tickers...\n")
    
    # Create cache directory if it doesn't exist
    cache_dir <- dirname(cache_file)
    if (!dir.exists(cache_dir)) {
      dir.create(cache_dir, recursive = TRUE)
    }
    
    # Fetch data for remaining tickers with incremental caching
    incremental_cache_func(
      tickers = tickers_to_fetch,
      cache_file = cache_file,
      ...
    )
    
  } else {
    cat("All requested tickers already in cache. No API calls needed.\n")
  }
  
  # Read the final cache file to return complete dataset
  cat("Reading final", data_type_name, "dataset from cache...\n")
  final_data <- cache_reader_func(cache_file)
  
  cat("Process complete. Total tickers in dataset:", length(unique(final_data$ticker)), "\n")
  
  # Get appropriate row description based on data type
  if (grepl("income", data_type_name, ignore.case = TRUE)) {
    cat("Total quarterly reports in dataset:", nrow(final_data), "\n")
  } else {
    cat("Total rows in dataset:", nrow(final_data), "\n")
  }
  
  return(final_data)
}
