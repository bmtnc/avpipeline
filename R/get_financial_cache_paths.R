#' Get Financial Statement Cache File Paths
#'
#' Returns a named list of cache file paths for all financial statement types.
#'
#' @return list: Named list with keys balance_sheet, cash_flow, income_statement, earnings
#' @keywords internal
get_financial_cache_paths <- function() {
  list(
    balance_sheet = "cache/balance_sheet_artifact.csv",
    cash_flow = "cache/cash_flow_artifact.csv",
    income_statement = "cache/income_statement_artifact.csv",
    earnings = "cache/earnings_artifact.csv"
  )
}
