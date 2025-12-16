#' Join All Financial Statements
#'
#' Joins all financial statements on ticker and fiscalDateEnding.
#'
#' @param statements list: Named list with earnings, cash_flow, income_statement, balance_sheet
#' @param valid_dates tibble: Valid ticker-fiscalDateEnding combinations
#' @return tibble: Joined financial statement data
#' @keywords internal
join_all_financial_statements <- function(statements, valid_dates) {
  if (!is.list(statements)) {
    stop(paste0(
      "join_all_financial_statements(): [statements] must be a list, not ",
      class(statements)[1]
    ))
  }

  validate_df_cols(valid_dates, c("ticker", "fiscalDateEnding"))

  final_tickers <- unique(valid_dates$ticker)
  earnings_final <- statements$earnings %>%
    dplyr::filter(ticker %in% final_tickers)
  cash_flow_final <- statements$cash_flow %>%
    dplyr::inner_join(valid_dates, by = c("ticker", "fiscalDateEnding"))
  income_statement_final <- statements$income_statement %>%
    dplyr::inner_join(valid_dates, by = c("ticker", "fiscalDateEnding"))
  balance_sheet_final <- statements$balance_sheet %>%
    dplyr::inner_join(valid_dates, by = c("ticker", "fiscalDateEnding"))

  joined_data <- valid_dates %>%
    dplyr::left_join(earnings_final, by = c("ticker", "fiscalDateEnding")) %>%
    dplyr::left_join(
      income_statement_final,
      by = c("ticker", "fiscalDateEnding"),
      suffix = c("", ".is")
    ) %>%
    dplyr::left_join(
      balance_sheet_final,
      by = c("ticker", "fiscalDateEnding"),
      suffix = c("", ".bs")
    ) %>%
    dplyr::left_join(
      cash_flow_final,
      by = c("ticker", "fiscalDateEnding"),
      suffix = c("", ".cf")
    ) %>%
    dplyr::select(
      -dplyr::any_of(c("as_of_date.is", "as_of_date.bs", "as_of_date.cf"))
    ) %>%
    dplyr::arrange(ticker, fiscalDateEnding)

  joined_data
}
