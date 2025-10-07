#' Remove All NA Financial Observations
#'
#' Orchestrates removal of all-NA observations across all 3 financial statements.
#'
#' @param statements list: Named list with cash_flow, income_statement, balance_sheet
#' @return list: Named list with cleaned versions of the 3 statements
#' @keywords internal
remove_all_na_financial_observations <- function(statements) {
  if (!is.list(statements)) {
    stop(paste0("remove_all_na_financial_observations(): [statements] must be a list, not ", class(statements)[1]))
  }

  required_names <- c("cash_flow", "income_statement", "balance_sheet")
  missing_names <- setdiff(required_names, names(statements))
  if (length(missing_names) > 0) {
    stop(paste0("remove_all_na_financial_observations(): [statements] must contain: ", paste(required_names, collapse = ", ")))
  }

  message(paste0("Identifying and removing observations with all NA financial columns..."))

  common_metadata_cols <- c("ticker", "fiscalDateEnding", "as_of_date", "reportedCurrency")

  cash_flow_financial_cols <- setdiff(names(statements$cash_flow), common_metadata_cols)
  income_statement_financial_cols <- setdiff(names(statements$income_statement), common_metadata_cols)
  balance_sheet_financial_cols <- setdiff(names(statements$balance_sheet), common_metadata_cols)

  cash_flow_cleaned <- identify_all_na_rows(statements$cash_flow, cash_flow_financial_cols, "cash flow")
  income_statement_cleaned <- identify_all_na_rows(statements$income_statement, income_statement_financial_cols, "income statement")
  balance_sheet_cleaned <- identify_all_na_rows(statements$balance_sheet, balance_sheet_financial_cols, "balance sheet")

  message(paste0("Data after removing all-NA observations:"))
  message(paste0("- Cash flow: ", nrow(cash_flow_cleaned), " observations"))
  message(paste0("- Income statement: ", nrow(income_statement_cleaned), " observations"))
  message(paste0("- Balance sheet: ", nrow(balance_sheet_cleaned), " observations"))

  list(
    cash_flow = cash_flow_cleaned,
    income_statement = income_statement_cleaned,
    balance_sheet = balance_sheet_cleaned
  )
}
