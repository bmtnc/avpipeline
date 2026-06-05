#' Overlay Interim Quotes onto Authoritative Price History
#'
#' Combines provisional daily bulk-quote bars with authoritative daily-adjusted
#' history under one rule: authoritative always wins on any shared date, and
#' interim bars contribute only for dates strictly beyond each ticker's
#' authoritative high-water mark. The weekly authoritative run therefore
#' supersedes interim bars automatically, with no overwrite step.
#'
#' @param authoritative tibble: canonical price history (ticker, date, ...)
#' @param interim tibble or NULL: normalized interim quotes (same schema)
#' @return tibble: merged price history, arranged by ticker, date
#' @keywords internal
merge_interim_quotes <- function(authoritative, interim) {
  validate_df_type(authoritative)

  if (is.null(interim) || nrow(interim) == 0) {
    return(authoritative)
  }
  validate_df_type(interim)

  high_water <- authoritative %>%
    dplyr::group_by(ticker) %>%
    dplyr::summarise(max_auth_date = max(date), .groups = "drop")

  fresh_interim <- interim %>%
    dplyr::left_join(high_water, by = "ticker") %>%
    dplyr::filter(is.na(max_auth_date) | date > max_auth_date) %>%
    dplyr::select(-max_auth_date)

  dplyr::bind_rows(authoritative, fresh_interim) %>%
    dplyr::arrange(ticker, date)
}
