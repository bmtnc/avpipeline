#' Cap Forward-Fill Staleness
#'
#' Blanks forward-filled financial columns on rows whose fill has outlived the
#' reporting cadence. Financials should never carry more than roughly one
#' quarter plus a reporting delay; beyond that the honest value is NA, not a
#' years-old number riding alongside a current price.
#'
#' @param data tibble: Daily-frequency data with forward-filled financials
#' @param financial_cols character: Columns to blank once stale (missing ones ignored)
#' @param max_fill_days numeric: Max days a reported value may carry forward (default: 180)
#' @return tibble: Data with stale financial values replaced by NA
#' @keywords internal
cap_forward_fill_staleness <- function(
  data,
  financial_cols,
  max_fill_days = 180
) {
  validate_df_cols(data, required_cols = c("date", "reportedDate"))
  if (!is.character(financial_cols)) {
    stop(
      "cap_forward_fill_staleness(): [financial_cols] must be a character vector"
    )
  }
  validate_positive(max_fill_days, name = "max_fill_days")

  fill_age_days <- as.numeric(data$date - data$reportedDate)
  is_stale <- !is.na(fill_age_days) & fill_age_days > max_fill_days

  data %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::any_of(financial_cols),
        ~ replace(., is_stale, NA)
      )
    )
}
