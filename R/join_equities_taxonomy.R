#' Join Equities Taxonomy to Add Subsector
#'
#' Left joins the `subsector` column onto a tibble that already has an `industry`
#' column, keyed on `industry`. Values are kept UPPERCASE (the artifact contract).
#' Rows whose `industry` is missing or unmapped get `NA` subsector.
#'
#' @param data tibble with an `industry` column
#' @return `data` with a `subsector` column added
#' @keywords internal
join_equities_taxonomy <- function(data) {
  validate_df_cols(data, "industry")

  taxonomy <- equities_taxonomy() %>%
    dplyr::select(industry, subsector)

  dplyr::left_join(data, taxonomy, by = "industry")
}
