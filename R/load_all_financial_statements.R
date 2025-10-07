#' Load All Financial Statements from Cache
#'
#' Loads all financial statement types from their respective cache files.
#'
#' @param cache_paths list: Named list of cache file paths (from get_financial_cache_paths())
#' @return list: Named list with balance_sheet, cash_flow, income_statement, earnings data
#' @keywords internal
load_all_financial_statements <- function(cache_paths) {
  if (!is.list(cache_paths)) {
    stop(paste0("load_all_financial_statements(): [cache_paths] must be a list, not ", class(cache_paths)[1]))
  }
  
  required_names <- c("balance_sheet", "cash_flow", "income_statement", "earnings")
  if (!all(required_names %in% names(cache_paths))) {
    stop(paste0("load_all_financial_statements(): [cache_paths] must contain keys: ", paste(required_names, collapse = ", ")))
  }
  
  message("\n=== Loading Cached Data ===")
  
  configs <- list(
    balance_sheet = BALANCE_SHEET_CONFIG,
    cash_flow = CASH_FLOW_CONFIG,
    income_statement = INCOME_STATEMENT_CONFIG,
    earnings = EARNINGS_CONFIG
  )
  
  list(
    balance_sheet = load_single_financial_type(cache_paths$balance_sheet, configs$balance_sheet),
    cash_flow = load_single_financial_type(cache_paths$cash_flow, configs$cash_flow),
    income_statement = load_single_financial_type(cache_paths$income_statement, configs$income_statement),
    earnings = load_single_financial_type(cache_paths$earnings, configs$earnings)
  )
}
