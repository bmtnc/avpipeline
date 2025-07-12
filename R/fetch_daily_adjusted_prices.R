
#' Fetch Daily Adjusted Price Data from Alpha Vantage
#'
#' Fetches daily OHLCV data with adjusted close values and dividend/split events
#' for a specified equity ticker using the Alpha Vantage API.
#'
#' @param ticker Character. The equity ticker (e.g., "IBM", "TSCO.LON")
#' @param outputsize Character. Either "compact" (latest 100 data points) or 
#'   "full" (20+ years of data). Default is "compact".
#' @param datatype Character. Either "json" or "csv". Default is "json".
#' @param api_key Character. Alpha Vantage API key. If NULL, will use 
#'   get_api_key() function.
#'
#' @return A tibble with daily adjusted price data
#' @export
fetch_daily_adjusted_prices <- function(ticker, 
                                       outputsize = "compact", 
                                       datatype = "json",
                                       api_key = NULL) {
  
  # Step 1: Validate inputs
  if (missing(ticker) || !is.character(ticker) || length(ticker) != 1) {
    stop("ticker must be a single character string")
  }
  
  if (!outputsize %in% c("compact", "full")) {
    stop("outputsize must be either 'compact' or 'full'")
  }
  
  if (!datatype %in% c("json", "csv")) {
    stop("datatype must be either 'json' or 'csv'")
  }
  
  # Step 2: Make API request
  response <- make_api_request(ticker, outputsize, datatype, api_key)
  
  # Step 3: Parse response to tibble
  parse_api_response(response, ticker, datatype)
}
