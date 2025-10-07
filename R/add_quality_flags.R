#' Add Quality Flags
#'
#' Adds has_complete_financials and has_earnings_metadata flags to financial statements.
#'
#' @param financial_statements tibble: Joined financial statement data
#' @return tibble: Financial statements with added quality flag columns
#' @keywords internal
add_quality_flags <- function(financial_statements) {
  if (!is.data.frame(financial_statements)) {
    stop(paste0("add_quality_flags(): [financial_statements] must be a data.frame, not ", class(financial_statements)[1]))
  }

  income_statement_cols <- intersect(get_income_statement_metrics(), names(financial_statements))
  balance_sheet_cols <- intersect(get_balance_sheet_metrics(), names(financial_statements))
  cash_flow_cols <- intersect(get_cash_flow_metrics(), names(financial_statements))

  financial_statements %>%
    dplyr::mutate(
      has_income_statement = dplyr::if_any(dplyr::all_of(income_statement_cols), ~ !is.na(.x)),
      has_balance_sheet = dplyr::if_any(dplyr::all_of(balance_sheet_cols), ~ !is.na(.x)),
      has_cash_flow = dplyr::if_any(dplyr::all_of(cash_flow_cols), ~ !is.na(.x)),
      has_complete_financials = has_income_statement & has_balance_sheet & has_cash_flow,
      has_earnings_metadata = !is.na(reportedDate)
    )
}
