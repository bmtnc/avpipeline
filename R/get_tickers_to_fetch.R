#' Get Tickers to Fetch
#'
#' Determines which tickers need to be fetched by comparing requested tickers
#' against tickers already present in cached data. Returns only the tickers
#' that are not already cached.
#'
#' @param requested_tickers Character vector of ticker symbols requested
#' @param cached_data Data frame containing cached price data with a 'ticker' column
#'
#' @return Character vector of tickers that need to be fetched
#'
#' @examples
#' \dontrun{
#' requested <- c("AAPL", "GOOGL", "MSFT", "TSLA")
#' cached_data <- read_cached_price_data("cache/price_data.csv")
#' tickers_to_fetch <- get_tickers_to_fetch(requested, cached_data)
#' }
#'
#' @export
get_tickers_to_fetch <- function(requested_tickers, cached_data) {
  
  # Validate inputs
  if (length(requested_tickers) == 0) {
    return(character(0))
  }
  
  # If no cached data, fetch all requested tickers
  if (is.null(cached_data) || nrow(cached_data) == 0) {
    return(requested_tickers)
  }
  
  # Check if ticker column exists in cached data
  if (!"ticker" %in% names(cached_data)) {
    stop("Cached data must contain a 'ticker' column")
  }
  
  # Get distinct tickers from cached data
  cached_tickers <- cached_data %>% 
    dplyr::distinct(ticker) %>% 
    dplyr::pull(ticker)
  
  # Return tickers that are not already cached
  tickers_to_fetch <- setdiff(requested_tickers, cached_tickers)
  
  return(tickers_to_fetch)
}
