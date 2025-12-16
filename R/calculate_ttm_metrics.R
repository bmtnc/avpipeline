#' Calculate TTM metrics for flow-based financial metrics only
#' @param data Financial statements data with quarterly metrics
#' @param flow_metrics Vector of flow-based column names (income statement + cash flow)
calculate_ttm_metrics <- function(data, flow_metrics) {
  data %>%
    dplyr::arrange(ticker, fiscalDateEnding) %>%
    dplyr::group_by(ticker) %>%
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
