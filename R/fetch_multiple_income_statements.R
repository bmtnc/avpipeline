#' Fetch Income Statement Data for Multiple Tickers
#'
#' Fetches quarterly income statement data for multiple equity symbols using
#' the Alpha Vantage API. Returns only quarterly data to avoid mixing annual
#' and quarterly numbers in time series analysis.
#'
#' @param tickers Character vector. Vector of equity symbols (e.g., c("IBM", "AAPL"))
#' @param api_key Character. Alpha Vantage API key. If NULL, will use 
#'   get_api_key() function.
#' @param delay_seconds Numeric. Delay between API calls in seconds. Default is 12
#'   to respect API rate limits (5 requests per minute).
#'
#' @return A tibble with quarterly income statement data for all tickers in long format
#' @export
fetch_multiple_income_statements <- function(tickers, 
                                            api_key = NULL,
                                            delay_seconds = 12) {
  
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
  results_list <- process_income_statements_with_progress(tickers, api_key, delay_seconds)
  
  # Step 4: Combine and process results
  combine_income_statement_results(results_list, tickers)
}
