#' Align Statement Tickers
#'
#' Finds tickers present in all 4 statements and filters to common tickers only.
#'
#' @param statements list: Named list with earnings, cash_flow, income_statement, balance_sheet
#' @return list: Named list with filtered statements (only common tickers)
#' @keywords internal
align_statement_tickers <- function(statements) {
  if (!is.list(statements)) {
    stop(paste0("align_statement_tickers(): [statements] must be a list, not ", class(statements)[1]))
  }

  required_names <- c("earnings", "cash_flow", "income_statement", "balance_sheet")
  missing_names <- setdiff(required_names, names(statements))
  if (length(missing_names) > 0) {
    stop(paste0("align_statement_tickers(): [statements] must contain: ", paste(required_names, collapse = ", ")))
  }

  earnings_tickers <- unique(statements$earnings$ticker)
  cash_flow_tickers <- unique(statements$cash_flow$ticker)
  income_statement_tickers <- unique(statements$income_statement$ticker)
  balance_sheet_tickers <- unique(statements$balance_sheet$ticker)

  all_tickers <- list(earnings_tickers, cash_flow_tickers, income_statement_tickers, balance_sheet_tickers)
  common_tickers <- Reduce(intersect, all_tickers)

  all_unique_tickers <- unique(c(earnings_tickers, cash_flow_tickers, income_statement_tickers, balance_sheet_tickers))
  removed_tickers <- setdiff(all_unique_tickers, common_tickers)

  if (length(removed_tickers) > 0) {
    message(paste0("Removed ", length(removed_tickers), " tickers not present in all 4 files:"))
    message(paste(removed_tickers, collapse = ", "))
  }

  list(
    earnings = statements$earnings %>% dplyr::filter(ticker %in% common_tickers),
    cash_flow = statements$cash_flow %>% dplyr::filter(ticker %in% common_tickers),
    income_statement = statements$income_statement %>% dplyr::filter(ticker %in% common_tickers),
    balance_sheet = statements$balance_sheet %>% dplyr::filter(ticker %in% common_tickers)
  )
}
