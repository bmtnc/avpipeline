#' Load All Artifact Statements
#'
#' Orchestrates loading of all 4 financial statement artifacts from cache files.
#'
#' @return list: Named list with earnings, cash_flow, income_statement, balance_sheet
#' @keywords internal
load_all_artifact_statements <- function() {
  cache_paths <- c(
    earnings = "cache/earnings_artifact.csv",
    cash_flow = "cache/cash_flow_artifact.csv",
    income_statement = "cache/income_statement_artifact.csv",
    balance_sheet = "cache/balance_sheet_artifact.csv"
  )

  validate_artifact_files(cache_paths)

  message(paste0("Loading financial statement data..."))

  earnings <- load_and_filter_financial_data(cache_paths["earnings"])
  cash_flow <- load_and_filter_financial_data(cache_paths["cash_flow"])
  income_statement <- load_and_filter_financial_data(cache_paths["income_statement"])
  balance_sheet <- load_and_filter_financial_data(cache_paths["balance_sheet"])

  message(paste0("Initial data loaded:"))
  message(paste0("- Earnings: ", nrow(earnings), " observations"))
  message(paste0("- Cash flow: ", nrow(cash_flow), " observations"))
  message(paste0("- Income statement: ", nrow(income_statement), " observations"))
  message(paste0("- Balance sheet: ", nrow(balance_sheet), " observations"))

  list(
    earnings = earnings,
    cash_flow = cash_flow,
    income_statement = income_statement,
    balance_sheet = balance_sheet
  )
}
