#' Align Statement Dates
#'
#' Finds aligned ticker-date combinations across the 3 financial statements.
#'
#' @param statements list: Named list with cash_flow, income_statement, balance_sheet
#' @return tibble: Valid ticker-fiscalDateEnding combinations
#' @keywords internal
align_statement_dates <- function(statements) {
  if (!is.list(statements)) {
    stop(paste0(
      "align_statement_dates(): [statements] must be a list, not ",
      class(statements)[1]
    ))
  }

  required_names <- c("cash_flow", "income_statement", "balance_sheet")
  missing_names <- setdiff(required_names, names(statements))
  if (length(missing_names) > 0) {
    stop(paste0(
      "align_statement_dates(): [statements] must contain: ",
      paste(required_names, collapse = ", ")
    ))
  }

  cash_flow_dates <- statements$cash_flow %>%
    dplyr::select(ticker, fiscalDateEnding) %>%
    dplyr::distinct() %>%
    dplyr::mutate(in_cash_flow = TRUE)

  income_statement_dates <- statements$income_statement %>%
    dplyr::select(ticker, fiscalDateEnding) %>%
    dplyr::distinct() %>%
    dplyr::mutate(in_income_statement = TRUE)

  balance_sheet_dates <- statements$balance_sheet %>%
    dplyr::select(ticker, fiscalDateEnding) %>%
    dplyr::distinct() %>%
    dplyr::mutate(in_balance_sheet = TRUE)

  date_alignment <- cash_flow_dates %>%
    dplyr::full_join(
      income_statement_dates,
      by = c("ticker", "fiscalDateEnding")
    ) %>%
    dplyr::full_join(
      balance_sheet_dates,
      by = c("ticker", "fiscalDateEnding")
    ) %>%
    dplyr::mutate(
      in_cash_flow = dplyr::coalesce(in_cash_flow, FALSE),
      in_income_statement = dplyr::coalesce(in_income_statement, FALSE),
      in_balance_sheet = dplyr::coalesce(in_balance_sheet, FALSE),
      in_all_three = in_cash_flow & in_income_statement & in_balance_sheet
    )

  total_observations <- nrow(date_alignment)
  valid_observations <- sum(date_alignment$in_all_three)
  removed_observations <- total_observations - valid_observations

  if (removed_observations > 0) {
    message(paste0(
      "Removed ",
      removed_observations,
      " observations with misaligned fiscalDateEnding dates across the 3 financial statement files"
    ))
  }

  valid_dates <- date_alignment %>%
    dplyr::filter(in_all_three) %>%
    dplyr::select(ticker, fiscalDateEnding)

  final_tickers <- unique(valid_dates$ticker)
  message(paste0(
    "Final dataset includes ",
    length(final_tickers),
    " tickers with ",
    nrow(valid_dates),
    " aligned observations"
  ))

  valid_dates
}
