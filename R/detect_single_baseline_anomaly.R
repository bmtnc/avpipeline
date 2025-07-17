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
detect_single_baseline_anomaly <- function(i, values, lookback, lookahead, threshold) {
  
  # Input validation - check types and lengths first
  if (!is.numeric(i) || length(i) != 1) {
    stop(paste0("Argument 'i' must be single numeric value, received: ", toString(i)))
  }
  
  if (!is.numeric(values)) {
    stop(paste0("Argument 'values' must be numeric vector, received: ", class(values)[1]))
  }
  
  if (length(values) == 0) {
    stop("Argument 'values' cannot be empty vector")
  }
  
  if (!is.numeric(lookback) || length(lookback) != 1) {
    stop(paste0("Argument 'lookback' must be single numeric value, received: ", toString(lookback)))
  }
  
  if (!is.numeric(lookahead) || length(lookahead) != 1) {
    stop(paste0("Argument 'lookahead' must be single numeric value, received: ", toString(lookahead)))
  }
  
  if (!is.numeric(threshold) || length(threshold) != 1) {
    stop(paste0("Argument 'threshold' must be positive numeric value, received: ", toString(threshold)))
  }
  
  # Check individual parameter constraints
  if (lookback < 1) {
    stop(paste0("Argument 'lookback' must be positive integer, received: ", toString(lookback)))
  }
  
  if (lookahead < 1) {
    stop(paste0("Argument 'lookahead' must be positive integer, received: ", toString(lookahead)))
  }
  
  if (is.na(threshold) || threshold <= 0) {
    stop(paste0("Argument 'threshold' must be positive numeric value, received: ", toString(threshold)))
  }
  
  # Check cross-parameter constraints (i vs values length)
  if (i < 1 || i > length(values)) {
    stop(paste0("Argument 'i' must be integer between 1 and ", length(values), 
                ", received: ", toString(i)))
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
  detect_baseline_anomaly(values[i], baseline_stats$baseline_median, 
                          baseline_stats$baseline_mad, threshold)
}