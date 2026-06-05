#' Derive Weekly Observation Dates from Daily Price Data
#'
#' @param price_data Tibble with at least a `date` column of daily prices
#' @param n_weeks Integer. Number of most recent weeks to return
#'
#' @return Date vector of the last trading day per week, most recent first
#' @export
derive_weekly_dates <- function(price_data, n_weeks = 52L) {
  validate_df_cols(price_data, required_cols = "date")

  if (nrow(price_data) == 0) {
    return(as.Date(character()))
  }

  n_weeks <- as.integer(n_weeks)
  if (is.na(n_weeks) || n_weeks < 1) {
    stop("n_weeks must be a positive integer")
  }

  weekly_dates <- price_data %>%
    dplyr::mutate(
      week_start = lubridate::floor_date(date, "week", week_start = 1)
    ) %>%
    dplyr::group_by(week_start) %>%
    dplyr::summarise(date = max(date), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(date)) %>%
    dplyr::slice_head(n = n_weeks) %>%
    dplyr::pull(date)

  weekly_dates
}
