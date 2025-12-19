#' Standardize to Calendar Quarters
#'
#' Maps fiscal dates to calendar quarter endings based on fiscal month.
#'
#' @param financial_statements tibble: Financial statements with fiscalDateEnding column
#' @return tibble: Financial statements with added calendar_quarter_ending column
#' @keywords internal
standardize_to_calendar_quarters <- function(financial_statements) {
  validate_df_cols(financial_statements, c("fiscalDateEnding"))

  financial_statements %>%
    dplyr::mutate(
      fiscal_month = lubridate::month(fiscalDateEnding),
      fiscal_year = lubridate::year(fiscalDateEnding),
      calendar_quarter_ending = dplyr::case_when(
        fiscal_month == 1 ~ as.Date(paste0(fiscal_year - 1, "-12-31")),
        fiscal_month %in% c(2, 3, 4) ~ as.Date(paste0(fiscal_year, "-03-31")),
        fiscal_month %in% c(5, 6, 7) ~ as.Date(paste0(fiscal_year, "-06-30")),
        fiscal_month %in% c(8, 9, 10) ~ as.Date(paste0(fiscal_year, "-09-30")),
        fiscal_month %in% c(11, 12) ~ as.Date(paste0(fiscal_year, "-12-31")),
        TRUE ~ fiscalDateEnding
      )
    ) %>%
    dplyr::select(-fiscal_month, -fiscal_year)
}
