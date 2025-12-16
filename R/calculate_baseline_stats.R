#' Calculate Baseline Statistics for Anomaly Detection
#'
#' Calculates median and MAD (Median Absolute Deviation) statistics from baseline values
#' for use in anomaly detection.
#'
#' @param values Numeric vector of time series values
#' @param indices Integer vector of indices to use for baseline calculation
#' @return Named list with baseline_median and baseline_mad values
#' @export
calculate_baseline_stats <- function(values, indices) {
  # Input validation
  validate_numeric_vector(values, allow_empty = TRUE, name = "values")
  validate_numeric_vector(indices, allow_empty = FALSE, name = "indices")

  if (any(indices < 1) || any(indices > length(values))) {
    stop(paste0(
      "Argument 'indices' contains out-of-bounds values. Valid range: 1 to ",
      length(values)
    ))
  }

  # Extract baseline values
  baseline_values <- values[indices]

  # Calculate statistics
  baseline_median <- median(baseline_values, na.rm = TRUE)
  baseline_mad <- mad(baseline_values, na.rm = TRUE)

  list(
    baseline_median = baseline_median,
    baseline_mad = baseline_mad
  )
}
