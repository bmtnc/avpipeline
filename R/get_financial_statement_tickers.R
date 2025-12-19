#' Get Ticker Symbols for Financial Statement Fetching
#'
#' Retrieves ticker symbols either from a specified ETF or from a manually provided list.
#'
#' @param etf_symbol character: ETF symbol to fetch holdings from (e.g., "SPY", "IWB")
#' @param manual_tickers character: Vector of ticker symbols to use directly
#' @return character: Vector of ticker symbols
#' @keywords internal
get_financial_statement_tickers <- function(
  etf_symbol = NULL,
  manual_tickers = NULL
) {
  if (is.null(etf_symbol) && is.null(manual_tickers)) {
    stop(paste0(
      "get_financial_statement_tickers(): At least one of [etf_symbol] or [manual_tickers] must be provided"
    ))
  }

  if (!is.null(etf_symbol)) {
    validate_character_scalar(etf_symbol, name = "etf_symbol")
  }

  if (!is.null(manual_tickers)) {
    if (!is.character(manual_tickers)) {
      stop(paste0(
        "get_financial_statement_tickers(): [manual_tickers] must be a character vector, not ",
        class(manual_tickers)[1]
      ))
    }
  }
  if (!is.null(manual_tickers)) {
    manual_tickers
  } else {
    fetch_etf_holdings(etf_symbol)
  }
}
