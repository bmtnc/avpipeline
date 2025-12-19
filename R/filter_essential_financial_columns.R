#' Filter Essential Financial Columns
#'
#' Filters to essential columns using metric getter functions.
#'
#' @param financial_statements tibble: Financial statements with all columns
#' @return tibble: Financial statements with only essential columns
#' @keywords internal
filter_essential_financial_columns <- function(financial_statements) {
  validate_df_type(financial_statements)

  financial_metrics <- c(
    get_cash_flow_metrics(),
    get_income_statement_metrics(),
    get_balance_sheet_metrics()
  )

  date_cols <- c("fiscalDateEnding", "calendar_quarter_ending", "reportedDate")
  meta_cols <- c("ticker", "reportedCurrency")

  essential_cols <- c(financial_metrics, date_cols, meta_cols)
  existing_essential_cols <- intersect(
    essential_cols,
    names(financial_statements)
  )

  filtered_data <- financial_statements %>%
    dplyr::select(dplyr::all_of(existing_essential_cols))

  filtered_data
}
