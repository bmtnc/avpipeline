#' Fetch All Financial Statements
#'
#' Fetches all financial statement types for specified tickers and updates cache files.
#'
#' @param tickers character: Vector of ticker symbols to fetch
#' @param cache_paths list: Named list of cache file paths (from get_financial_cache_paths())
#' @return invisible NULL (updates all cache files as side effect)
#' @keywords internal
fetch_all_financial_statements <- function(tickers, cache_paths) {
  if (!is.character(tickers)) {
    stop(paste0(
      "fetch_all_financial_statements(): [tickers] must be a character vector, not ",
      class(tickers)[1]
    ))
  }
  if (!is.list(cache_paths)) {
    stop(paste0(
      "fetch_all_financial_statements(): [cache_paths] must be a list, not ",
      class(cache_paths)[1]
    ))
  }

  required_names <- c(
    "balance_sheet",
    "cash_flow",
    "income_statement",
    "earnings"
  )
  if (!all(required_names %in% names(cache_paths))) {
    stop(paste0(
      "fetch_all_financial_statements(): [cache_paths] must contain keys: ",
      paste(required_names, collapse = ", ")
    ))
  }

  configs <- list(
    balance_sheet = BALANCE_SHEET_CONFIG,
    cash_flow = CASH_FLOW_CONFIG,
    income_statement = INCOME_STATEMENT_CONFIG,
    earnings = EARNINGS_CONFIG
  )

  fetch_single_financial_type(
    tickers,
    configs$balance_sheet,
    cache_paths$balance_sheet
  )
  fetch_single_financial_type(tickers, configs$cash_flow, cache_paths$cash_flow)
  fetch_single_financial_type(
    tickers,
    configs$income_statement,
    cache_paths$income_statement
  )
  fetch_single_financial_type(tickers, configs$earnings, cache_paths$earnings)

  invisible(NULL)
}
