#' Forward Fill Financial Data
#'
#' Forward fills financial data by ticker group using tidyr::fill().
#' This propagates the most recent financial statement values forward to
#' subsequent dates until new financial data is reported. When series_run_id
#' is present, values fill within a run only — a post-gap quarter with NA TTM
#' must stay NA rather than inherit the prior run's stale value.
#'
#' @param data tibble: Data frame with ticker and financial metrics
#' @return tibble: Data frame with forward-filled financial metrics
#' @keywords internal
forward_fill_financial_data <- function(data) {
  validate_df_cols(data, required_cols = "ticker")

  if (!"series_run_id" %in% names(data)) {
    return(
      data %>%
        dplyr::group_by(ticker) %>%
        tidyr::fill(dplyr::everything(), .direction = "down") %>%
        dplyr::ungroup()
    )
  }

  data %>%
    dplyr::group_by(ticker) %>%
    tidyr::fill(series_run_id, .direction = "down") %>%
    dplyr::group_by(ticker, series_run_id) %>%
    tidyr::fill(dplyr::everything(), .direction = "down") %>%
    dplyr::ungroup()
}
