#' Get Ticker Symbols for Financial Statement Fetching
#'
#' Retrieves ticker symbols either from a specified ETF or from a manually provided list.
#'
#' @param etf_symbol character: ETF symbol to fetch holdings from (e.g., "SPY", "IWB")
#' @param manual_tickers character: Vector of ticker symbols to use directly
#' @return character: Vector of ticker symbols
#' @keywords internal
get_financial_statement_tickers <- function(etf_symbol = NULL, manual_tickers = NULL) {
  if (is.null(etf_symbol) && is.null(manual_tickers)) {
    stop(paste0("get_financial_statement_tickers(): At least one of [etf_symbol] or [manual_tickers] must be provided"))
  }
  
  if (!is.null(etf_symbol) && (!is.character(etf_symbol) || length(etf_symbol) != 1)) {
    stop(paste0("get_financial_statement_tickers(): [etf_symbol] must be a character scalar, not ", class(etf_symbol)[1], " of length ", length(etf_symbol)))
  }
  
  if (!is.null(manual_tickers) && !is.character(manual_tickers)) {
    stop(paste0("get_financial_statement_tickers(): [manual_tickers] must be a character vector, not ", class(manual_tickers)[1]))
  }
  
  if (!is.null(manual_tickers)) {
    message(paste0("Using ", length(manual_tickers), " manually provided tickers"))
    manual_tickers
  } else {
    message(paste0("Fetching holdings for ETF: ", etf_symbol))
    tickers <- fetch_etf_holdings(etf_symbol)
    message(paste0("Retrieved ", length(tickers), " tickers from ETF: ", etf_symbol))
    tickers
  }
}
