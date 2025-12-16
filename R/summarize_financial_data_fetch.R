#' Summarize Financial Data Fetch Results
#'
#' Displays summary statistics for fetched financial data.
#'
#' @param etf_symbol character: ETF symbol used (or NULL if manual tickers)
#' @param tickers character: Vector of ticker symbols processed
#' @param data_list list: Named list of loaded financial data
#' @return invisible NULL (prints summary as side effect)
#' @keywords internal
summarize_financial_data_fetch <- function(etf_symbol, tickers, data_list) {
  if (
    !is.null(etf_symbol) &&
      (!is.character(etf_symbol) || length(etf_symbol) != 1)
  ) {
    stop(paste0(
      "summarize_financial_data_fetch(): [etf_symbol] must be NULL or a character scalar, not ",
      class(etf_symbol)[1],
      " of length ",
      length(etf_symbol)
    ))
  }
  if (!is.character(tickers)) {
    stop(paste0(
      "summarize_financial_data_fetch(): [tickers] must be a character vector, not ",
      class(tickers)[1]
    ))
  }
  if (!is.list(data_list)) {
    stop(paste0(
      "summarize_financial_data_fetch(): [data_list] must be a list, not ",
      class(data_list)[1]
    ))
  }

  required_names <- c(
    "balance_sheet",
    "cash_flow",
    "income_statement",
    "earnings"
  )
  if (!all(required_names %in% names(data_list))) {
    stop(paste0(
      "summarize_financial_data_fetch(): [data_list] must contain keys: ",
      paste(required_names, collapse = ", ")
    ))
  }

  message("\n=== Summary ===")
  if (!is.null(etf_symbol)) {
    message(paste0("ETF Symbol: ", etf_symbol))
  }
  message(paste0("Number of tickers processed: ", length(tickers)))
  message(
    "Data types fetched: Balance Sheet, Cash Flow, Income Statement, Earnings"
  )
  message("Cache files updated in cache/ directory")
  message("\nAvailable data objects:")
  message("- bs: Balance Sheet data")
  message("- cf: Cash Flow data")
  message("- is: Income Statement data")
  message("- meta: Earnings data")

  invisible(NULL)
}
