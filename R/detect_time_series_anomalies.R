#' Detect Anomalous Values in Time Series Using Mean Absolute Deviation
#'
#' Calculates anomaly flags for time series values using Mean Absolute Deviation (MAD) threshold.
#' Values that exceed the MAD threshold relative to the historical median are flagged as anomalous.
#'
#' @param values Numeric vector of time series values to analyze for anomalies
#' @param threshold Numeric value specifying the MAD threshold multiplier (default: 3)
#' @param min_observations Integer specifying minimum number of observations required for MAD calculation (default: 10)
#'
#' @return Logical vector of same length as input, with TRUE indicating anomalous values
#' @export
detect_time_series_anomalies <- function(
  values,
  threshold = 3,
  min_observations = 10
) {
  if (!is.numeric(values)) {
    stop(paste0(
      "Argument 'values' must be numeric. Received: ",
      class(values)[1]
    ))
  }
  if (length(values) == 0) {
    return(logical(0))
  }
  if (any(is.na(values))) {
    stop(paste0(
      "Argument 'values' contains NA values. Found ",
      sum(is.na(values)),
      " NA values out of ",
      length(values),
      " total values."
    ))
  }
  validate_positive(threshold, name = "threshold")
  validate_numeric_scalar(min_observations, name = "min_observations", gte = 1)
  # Check if we have enough observations
  if (length(values) < min_observations) {
    stop(paste0(
      "Insufficient observations for anomaly detection. Need at least ",
      min_observations,
      " but got ",
      length(values),
      "."
    ))
  }

  median_value <- stats::median(values)
  absolute_deviations <- abs(values - median_value)
  mad_value <- stats::median(absolute_deviations)

  # Handle case where MAD is zero (all values are the same)
  if (mad_value == 0) {
    return(rep(FALSE, length(values)))
  }

  # Calculate anomaly threshold and identify anomalies
  anomaly_threshold <- mad_value * threshold
  anomalies <- abs(values - median_value) > anomaly_threshold

  anomalies
}
