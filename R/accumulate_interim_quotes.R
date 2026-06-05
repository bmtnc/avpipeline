#' Accumulate New Interim Quotes onto the Existing Store
#'
#' Combines the existing interim store with a freshly fetched batch under one
#' rule: the newest bar wins for any repeated (ticker, date). This lets multiple
#' daily runs between weekly reconciliations each contribute bars, while a re-run
#' on the same day simply replaces that day's bar.
#'
#' @param existing tibble or NULL: prior interim store (price artifact schema)
#' @param new_quotes tibble: freshly normalized interim quotes (same schema)
#' @return tibble: deduplicated store, arranged by ticker, date
#' @keywords internal
accumulate_interim_quotes <- function(existing, new_quotes) {
  validate_df_type(new_quotes)
  if (!is.null(existing)) {
    validate_df_type(existing)
  }

  dplyr::bind_rows(existing, new_quotes) %>%
    dplyr::arrange(ticker, date) %>%
    dplyr::group_by(ticker, date) %>%
    dplyr::slice_tail(n = 1) %>%
    dplyr::ungroup()
}
