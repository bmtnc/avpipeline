#' Validate Quarterly Continuity
#'
#' Orchestrates quarterly continuity validation across all tickers using split-apply-combine.
#'
#' @param financial_statements tibble: Financial statements data
#' @return tibble: Financial statements with only continuous quarterly series
#' @export
validate_quarterly_continuity <- function(financial_statements) {
  validate_df_cols(financial_statements, c("ticker", "fiscalDateEnding"))

  quarterly_results <- financial_statements %>%
    dplyr::group_by(ticker) %>%
    dplyr::arrange(ticker, fiscalDateEnding) %>%
    dplyr::mutate(row_num = dplyr::row_number()) %>%
    dplyr::ungroup() %>%
    split(.$ticker) %>%
    lapply(validate_continuous_quarters) %>%
    dplyr::bind_rows()

  quarterly_results
}
