#' Add per-share metrics to dataset with shares outstanding
#' @param data Dataset with financial metrics and shares outstanding
#' @param metrics_to_convert Vector of column names to convert to per-share
#' @param shares_col Name of shares outstanding column
calculate_per_share_metrics <- function(
  data,
  metrics_to_convert,
  shares_col = "commonStockSharesOutstanding"
) {
  existing_metrics <- intersect(metrics_to_convert, names(data))
  numeric_metrics <- existing_metrics[sapply(existing_metrics, function(col) {
    is.numeric(data[[col]])
  })]
  non_per_share_metrics <- numeric_metrics[
    !grepl("_per_share$", numeric_metrics)
  ]

  data %>%
    dplyr::mutate(
      valid_shares = !is.na(!!rlang::sym(shares_col)) &
        !!rlang::sym(shares_col) > 0,
      dplyr::across(
        dplyr::all_of(non_per_share_metrics),
        ~ dplyr::if_else(
          valid_shares & !is.na(.),
          . / !!rlang::sym(shares_col),
          NA_real_
        ),
        .names = "{.col}_per_share"
      )
    ) %>%
    dplyr::select(-valid_shares)
}
