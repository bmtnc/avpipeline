#' Determine if Value is Baseline Anomaly
#'
#' Determines if a single value is anomalous based on baseline statistics and threshold.
#'
#' @param value Numeric value to test for anomaly
#' @param baseline_median Numeric baseline median value
#' @param baseline_mad Numeric baseline MAD (Median Absolute Deviation) value
#' @param threshold Numeric threshold multiplier for MAD detection
#' @return Logical value, TRUE if value is anomalous
#' @export
detect_baseline_anomaly <- function(value, baseline_median, baseline_mad, threshold) {
  
  # Input validation
  if (!is.numeric(value) || length(value) != 1) {
    stop(paste0("Argument 'value' must be single numeric value, received: ", 
                class(value)[1], " of length ", length(value)))
  }
  
  if (!is.numeric(baseline_median) || length(baseline_median) != 1) {
    stop(paste0("Argument 'baseline_median' must be single numeric value, received: ", 
                class(baseline_median)[1], " of length ", length(baseline_median)))
  }
  
  if (!is.numeric(baseline_mad) || length(baseline_mad) != 1) {
    stop(paste0("Argument 'baseline_mad' must be single numeric value, received: ", 
                class(baseline_mad)[1], " of length ", length(baseline_mad)))
  }
  
  if (!is.numeric(threshold) || length(threshold) != 1) {
    stop(paste0("Argument 'threshold' must be positive numeric value, received: ", toString(threshold)))
  }
  
  if (is.na(threshold) || threshold <= 0) {
    stop(paste0("Argument 'threshold' must be positive numeric value, received: ", toString(threshold)))
  }
  
  # Handle NA or zero MAD cases
  if (is.na(value) || is.na(baseline_median) || is.na(baseline_mad) || baseline_mad <= 0) {
    return(FALSE)
  }
  
  # Calculate anomaly
  abs(value - baseline_median) > threshold * baseline_mad
}