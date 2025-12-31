#' Add Per-Share Columns to Dataset
#'
#' Creates new columns with `_per_share` suffix by dividing specified columns
#' by shares outstanding.
#'
#' @param data tibble: Dataset containing financial metrics and shares outstanding
#' @param cols character: Column names to convert to per-share
#' @param shares_col character: Name of shares column (default: "commonStockSharesOutstanding")
#' @return tibble: Original data with new `*_per_share` columns added
#' @export
add_per_share_columns <- function(
  data,
  cols,
  shares_col = "commonStockSharesOutstanding"
) {
  validate_df_cols(data, c(cols, shares_col))

  for (col in cols) {
    validate_numeric_vector(data[[col]], allow_empty = TRUE, name = col)
  }
  validate_numeric_vector(
    data[[shares_col]],
    allow_empty = TRUE,
    name = shares_col
  )

  # Skip columns that already have _per_share suffix
  cols <- cols[!grepl("_per_share$", cols)]

  if (length(cols) == 0) {
    return(data)
  }

  data %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(cols),
        ~ dplyr::if_else(
          !is.na(.data[[shares_col]]) & .data[[shares_col]] > 0 & !is.na(.x),
          .x / .data[[shares_col]],
          NA
        ),
        .names = "{.col}_per_share"
      )
    )
}
