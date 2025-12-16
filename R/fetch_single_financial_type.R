#' Fetch Financial Data for Single Data Type
#'
#' Fetches financial data for a specific data type (e.g., balance sheet, cash flow)
#' and updates the cache file.
#'
#' @param tickers character: Vector of ticker symbols to fetch
#' @param config list: Configuration object (e.g., BALANCE_SHEET_CONFIG)
#' @param cache_path character: Path to cache file for this data type
#' @return invisible NULL (updates cache file as side effect)
#' @keywords internal
fetch_single_financial_type <- function(tickers, config, cache_path) {
  if (!is.character(tickers)) {
    stop(paste0(
      "fetch_single_financial_type(): [tickers] must be a character vector, not ",
      class(tickers)[1]
    ))
  }
  if (!is.list(config)) {
    stop(paste0(
      "fetch_single_financial_type(): [config] must be a list, not ",
      class(config)[1]
    ))
  }
  if (!is.character(cache_path) || length(cache_path) != 1) {
    stop(paste0(
      "fetch_single_financial_type(): [cache_path] must be a character scalar, not ",
      class(cache_path)[1],
      " of length ",
      length(cache_path)
    ))
  }

  message(paste0("\n=== Processing ", config$data_type_name, " Data ==="))

  fetch_multiple_tickers_with_cache(
    tickers = tickers,
    cache_file = cache_path,
    single_fetch_func = function(ticker, ...) {
      fetch_single_ticker_data(ticker, config, ...)
    },
    cache_reader_func = read_cached_data_parquet,
    data_type_name = config$data_type_name,
    delay_seconds = config$default_delay
  )

  invisible(NULL)
}
