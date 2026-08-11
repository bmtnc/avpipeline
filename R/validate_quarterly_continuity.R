#' Validate Quarterly Continuity
#'
#' Annotates quarterly series structure instead of filtering to one continuous
#' chunk. Consecutive quarters (3 calendar months apart, month-end dates) share
#' a `series_run_id`; a break starts a new run with `gap_before = TRUE`. All
#' quarters are kept so a single missing quarter at the source cannot discard
#' current data; TTM calculations group by run to avoid summing across gaps.
#' Non-month-end dates are dropped.
#'
#' @param financial_statements tibble: Financial statements data
#' @return tibble: Financial statements with series_run_id, gap_before, and
#'   has_discontinuous_series columns
#' @export
validate_quarterly_continuity <- function(financial_statements) {
  validate_df_cols(financial_statements, c("ticker", "fiscalDateEnding"))

  financial_statements %>%
    dplyr::filter(
      lubridate::day(fiscalDateEnding) ==
        lubridate::days_in_month(fiscalDateEnding)
    ) %>%
    dplyr::arrange(ticker, fiscalDateEnding) %>%
    dplyr::group_by(ticker) %>%
    dplyr::mutate(
      month_index = 12 * lubridate::year(fiscalDateEnding) +
        lubridate::month(fiscalDateEnding),
      gap_before = dplyr::coalesce(
        month_index - dplyr::lag(month_index) != 3,
        FALSE
      ),
      series_run_id = cumsum(gap_before) + 1L,
      has_discontinuous_series = any(gap_before)
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(-month_index)
}
