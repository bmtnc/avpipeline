#' Clean Original Columns by Replacing Anomalies with Interpolated Values
#'
#' Replaces anomalous values (marked by anomaly flag columns) with NA and then
#' interpolates using linear interpolation. Handles failures gracefully at the
#' column level by keeping original data for failed columns.
#'
#' @param data Data frame with original metrics and corresponding anomaly flag columns
#' @param metric_cols Character vector of column names to clean
#' @return Data frame with cleaned metric columns (anomaly flag columns preserved)
#' @export
clean_original_columns <- function(data, metric_cols) {
  if (!is.character(metric_cols) || length(metric_cols) == 0) {
    stop(paste0(
      "Argument 'metric_cols' must be non-empty character vector, received: ",
      class(metric_cols)[1],
      " of length ",
      length(metric_cols)
    ))
  }

  validate_df_cols(data, metric_cols)
  validate_non_empty(data, name = "data")

  result <- data

  for (metric in metric_cols) {
    anomaly_col <- paste0(metric, "_anomaly")

    # Check if anomaly column exists
    if (anomaly_col %in% names(result)) {
      tryCatch(
        {
          result <- result %>%
            dplyr::mutate(
              !!rlang::sym(metric) := zoo::na.approx(
                ifelse(!!rlang::sym(anomaly_col), NA, !!rlang::sym(metric)),
                na.rm = FALSE
              )
            )
        },
        error = function(e) {
          warning(paste0(
            "Failed to clean column '",
            metric,
            "'. Error: ",
            e$message
          ))
          # Keep original data for this column if cleaning fails
        }
      )
    } else {
      warning(paste0(
        "Anomaly column '",
        anomaly_col,
        "' not found for metric '",
        metric,
        "'. Skipping cleaning."
      ))
    }
  }

  result
}
