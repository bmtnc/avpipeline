#' Detect Single Baseline Anomaly
#'
#' Orchestrates baseline anomaly detection for a single position in the time series.
#'
#' @param i Integer position in the time series to analyze
#' @param values Numeric vector of time series values
#' @param lookback Integer number of periods to look back for baseline calculation
#' @param lookahead Integer number of periods to look ahead for baseline calculation
#' @param threshold Numeric threshold multiplier for MAD detection
#' @return Logical value, TRUE if position i is anomalous
#' @export
detect_single_baseline_anomaly <- function(
  i,
  values,
  lookback,
  lookahead,
  threshold
) {
  validate_numeric_scalar(i, name = "i")
  validate_numeric_vector(values, allow_empty = FALSE, name = "values")
  validate_numeric_scalar(lookback, name = "lookback", gte = 1)
  validate_numeric_scalar(lookahead, name = "lookahead", gte = 1)
  validate_positive(threshold, name = "threshold")
  # Check cross-parameter constraints (i vs values length)
  if (i < 1 || i > length(values)) {
    stop(paste0(
      "Argument 'i' must be integer between 1 and ",
      length(values),
      ", received: ",
      toString(i)
    ))
  }

  n <- length(values)

  # Calculate baseline indices
  baseline_indices <- calculate_baseline(i, n, lookback, lookahead)

  # Need minimum baseline points for reliable detection
  if (length(baseline_indices) < 6) {
    return(FALSE)
  }

  # Calculate baseline statistics
  baseline_stats <- calculate_baseline_stats(values, baseline_indices)

  # Determine if current value is anomalous
  detect_baseline_anomaly(
    values[i],
    baseline_stats$baseline_median,
    baseline_stats$baseline_mad,
    threshold
  )
}
