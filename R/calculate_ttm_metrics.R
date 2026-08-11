#' Calculate TTM metrics for flow-based financial metrics only
#'
#' Rolling 4-quarter sums are computed within a ticker's contiguous series run
#' (series_run_id, when present) so TTM never spans a reporting gap.
#'
#' @param data Financial statements data with quarterly metrics
#' @param flow_metrics Vector of flow-based column names (income statement + cash flow)
calculate_ttm_metrics <- function(data, flow_metrics) {
  group_cols <- intersect(c("ticker", "series_run_id"), names(data))

  data %>%
    dplyr::arrange(ticker, fiscalDateEnding) %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(flow_metrics),
        ~ dplyr::if_else(
          dplyr::row_number() >= 4,
          zoo::rollapply(
            dplyr::coalesce(., 0),
            width = 4,
            FUN = sum,
            align = "right",
            fill = NA,
            na.rm = TRUE
          ),
          NA_real_
        ),
        .names = "{.col}_ttm"
      )
    ) %>%
    dplyr::ungroup()
}
