#' Fetch Multiple Tickers with Caching
#'
#' Fetches daily adjusted price data for multiple tickers with intelligent caching
#' to avoid redundant API calls. Checks cache file for existing data and only
#' fetches data for tickers not already cached.
#'
#' @param tickers Character vector of ticker symbols to fetch
#' @param cache_file Path to cache file (CSV format)
#' @param outputsize Character, either "compact" (latest 100 days) or "full" (20+ years)
#' @param datatype Character, data format ("json" or "csv")
#' @param as_of_date Date, timestamp for when data was pulled (defaults to current date)
#'
#' @return A tibble with price data for all requested tickers
#'
#' @examples
#' \dontrun{
#' tickers <- c("AAPL", "GOOGL", "MSFT")
#' price_data <- fetch_multiple_tickers_with_cache(
#'   tickers = tickers,
#'   cache_file = "cache/price_data.csv"
#' )
#' }
#'
#' @export
fetch_multiple_tickers_with_cache <- function(tickers, 
                                              cache_file,
                                              outputsize = "full",
                                              datatype = "json",
                                              as_of_date = Sys.Date()) {
  
  # Validate inputs
  if (length(tickers) == 0) {
    stop("No tickers provided")
  }
  
  if (missing(cache_file)) {
    stop("cache_file parameter is required")
  }
  
  # Initialize variables
  existing_data <- NULL
  tickers_to_fetch <- tickers
  
  # Check if cache file exists and process accordingly
  if (file.exists(cache_file)) {
    cat("Cache file found. Reading existing data...\n")
    
    # Read existing cached data
    existing_data <- read_cached_price_data(cache_file)
    
    # Get tickers that need to be fetched
    tickers_to_fetch <- get_tickers_to_fetch(tickers, existing_data)
    
    # Get distinct tickers from existing data for reporting
    cached_tickers <- existing_data %>% 
      dplyr::distinct(ticker) %>% 
      dplyr::pull(ticker)
    
    cat("Tickers in cache:", paste(cached_tickers, collapse = ", "), "\n")
    cat("Tickers to fetch:", paste(tickers_to_fetch, collapse = ", "), "\n")
    
  } else {
    cat("No cache file found. Will fetch data for all tickers.\n")
  }
  
  # Fetch data only for tickers not in cache
  if (length(tickers_to_fetch) > 0) {
    cat("Fetching data from Alpha Vantage for", length(tickers_to_fetch), "tickers...\n")
    
    # Fetch daily adjusted price data for remaining tickers
    new_price_data <- fetch_multiple_tickers(
      tickers = tickers_to_fetch,
      outputsize = outputsize,
      datatype = datatype
    )
    
    # Process and combine data
    price_object <- combine_and_process_price_data(existing_data, new_price_data, as_of_date)
    
  } else {
    cat("All requested tickers already in cache. No API calls needed.\n")
    price_object <- existing_data
  }
  
  # Save updated data to cache
  cat("Saving updated data to cache...\n")
  
  # Create cache directory if it doesn't exist
  cache_dir <- dirname(cache_file)
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }
  
  write.csv(price_object, cache_file, row.names = FALSE)
  
  cat("Process complete. Total tickers in dataset:", length(unique(price_object$ticker)), "\n")
  cat("Total rows in dataset:", nrow(price_object), "\n")
  
  return(price_object)
}
