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
  if (!is.numeric(values)) {
    stop(paste0(
      "Argument 'values' must be numeric vector, received: ",
      class(values)[1]
    ))
  }

  if (!is.numeric(indices) || length(indices) == 0) {
    stop(paste0(
      "Argument 'indices' must be non-empty integer vector, received: ",
      class(indices)[1],
      " of length ",
      length(indices)
    ))
  }

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
