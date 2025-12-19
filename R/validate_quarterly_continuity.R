#' Validate Quarterly Continuity
#'
#' Orchestrates quarterly continuity validation across all tickers using split-apply-combine.
#'
#' @param financial_statements tibble: Financial statements data
#' @return tibble: Financial statements with only continuous quarterly series
#' @keywords internal
validate_quarterly_continuity <- function(financial_statements) {
  validate_df_cols(financial_statements, c("ticker", "fiscalDateEnding"))

  original_data <- financial_statements %>%
    dplyr::select(ticker, fiscalDateEnding) %>%
    dplyr::arrange(ticker, fiscalDateEnding)

  quarterly_results <- financial_statements %>%
    dplyr::group_by(ticker) %>%
    dplyr::arrange(ticker, fiscalDateEnding) %>%
    dplyr::mutate(row_num = dplyr::row_number()) %>%
    dplyr::ungroup() %>%
    split(.$ticker) %>%
    lapply(validate_continuous_quarters) %>%
    dplyr::bind_rows()

  final_data <- quarterly_results %>%
    dplyr::select(ticker, fiscalDateEnding) %>%
    dplyr::arrange(ticker, fiscalDateEnding)

  removed_obs <- nrow(original_data) - nrow(final_data)
  completely_removed_tickers <- setdiff(
    unique(original_data$ticker),
    unique(final_data$ticker)
  )

  quarterly_results
}
