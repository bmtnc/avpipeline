#' Fetch Daily Adjusted Price Data for Multiple Tickers
#'
#' Fetches daily adjusted price data for multiple equity symbols from Alpha Vantage
#' and combines them into a single long-format dataframe.
#'
#' @param tickers Character vector. Vector of equity symbols (e.g., c("IBM", "AAPL"))
#' @param outputsize Character. Either "compact" (latest 100 data points) or 
#'   "full" (20+ years of data). Default is "compact".
#' @param datatype Character. Either "json" or "csv". Default is "json".
#' @param api_key Character. Alpha Vantage API key. If NULL, will use 
#'   get_api_key() function.
#' @param delay_seconds Numeric. Delay between API calls in seconds. Default is 0.5
#'   to respect API rate limits.
#'
#' @return A tibble with daily adjusted price data for all tickers in long format
#' @export
fetch_multiple_tickers <- function(tickers, 
                                  outputsize = "compact", 
                                  datatype = "json",
                                  api_key = NULL,
                                  delay_seconds = 1) {
  
  # Step 1: Validate inputs
  if (missing(tickers) || !is.character(tickers) || length(tickers) == 0) {
    stop("tickers must be a non-empty character vector")
  }
  
  if (!is.numeric(delay_seconds) || delay_seconds < 0) {
    stop("delay_seconds must be a non-negative number")
  }
  
  # Step 2: Get API key once
  if (is.null(api_key)) {
    api_key <- get_api_key()
  }
  
  # Step 3: Process all tickers with progress tracking
  results_list <- process_tickers_with_progress(tickers, outputsize, datatype, api_key, delay_seconds)
  
  # Step 4: Combine and process results
  combine_ticker_results(results_list, tickers)
}
