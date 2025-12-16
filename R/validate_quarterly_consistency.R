#' Validate Quarterly Data Consistency
#'
#' Compares overlapping quarters between old and new data to detect unexpected changes.
#'
#' @param existing_data data.frame: Previously stored quarterly data
#' @param new_data data.frame: Newly fetched quarterly data
#' @param key_metrics character: Metric columns to compare (default: totalRevenue, netIncome)
#' @param tolerance numeric: Allowed difference threshold (default: 0.01)
#' @return list: valid (logical), mismatches (data.frame or NULL)
#' @keywords internal
validate_quarterly_consistency <- function(
  existing_data,
  new_data,
  key_metrics = c("totalRevenue", "netIncome"),
  tolerance = 0.01
) {
  if (is.null(existing_data) || nrow(existing_data) == 0) {
    return(list(valid = TRUE, mismatches = NULL))
  }

  tryCatch(
    validate_df_type(new_data),
    error = function(e) return(list(valid = TRUE, mismatches = NULL))
  )

  if (nrow(new_data) == 0) {
    return(list(valid = TRUE, mismatches = NULL))
  }

  # Find overlapping quarters
  join_cols <- c("ticker", "fiscalDateEnding")
  existing_cols <- names(existing_data)
  new_cols <- names(new_data)

  if (!all(join_cols %in% existing_cols) || !all(join_cols %in% new_cols)) {
    return(list(valid = TRUE, mismatches = NULL))
  }

  # Filter to metrics that exist in both datasets
  available_metrics <- key_metrics[
    key_metrics %in% existing_cols & key_metrics %in% new_cols
  ]

  if (length(available_metrics) == 0) {
    return(list(valid = TRUE, mismatches = NULL))
  }

  # Select only needed columns for comparison
  existing_subset <- existing_data[,
    c(join_cols, available_metrics),
    drop = FALSE
  ]
  new_subset <- new_data[, c(join_cols, available_metrics), drop = FALSE]

  overlap <- dplyr::inner_join(
    existing_subset,
    new_subset,
    by = join_cols,
    suffix = c("_old", "_new")
  )

  if (nrow(overlap) == 0) {
    return(list(valid = TRUE, mismatches = NULL))
  }

  # Check each metric for mismatches
  mismatch_flags <- lapply(available_metrics, function(metric) {
    old_col <- paste0(metric, "_old")
    new_col <- paste0(metric, "_new")

    old_vals <- overlap[[old_col]]
    new_vals <- overlap[[new_col]]

    # Handle NA values - NA to NA is not a mismatch
    both_na <- is.na(old_vals) & is.na(new_vals)
    one_na <- xor(is.na(old_vals), is.na(new_vals))

    # For numeric comparisons, check absolute difference
    numeric_diff <- !is.na(old_vals) &
      !is.na(new_vals) &
      abs(old_vals - new_vals) > tolerance

    one_na | numeric_diff
  })

  any_mismatch <- Reduce(`|`, mismatch_flags)

  if (!any(any_mismatch)) {
    return(list(valid = TRUE, mismatches = NULL))
  }

  mismatches <- overlap[any_mismatch, , drop = FALSE]

  list(valid = FALSE, mismatches = mismatches)
}
