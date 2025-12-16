#' Calculate Baseline Indices for Anomaly Detection
#'
#' Calculates which indices should be used for baseline calculation for a given position,
#' excluding the current point and immediate neighbors to prevent contamination.
#'
#' @param i Integer position in the time series for which to calculate baseline indices
#' @param n Integer length of the time series
#' @param lookback Integer number of periods to look back for baseline calculation
#' @param lookahead Integer number of periods to look ahead for baseline calculation
#' @return Integer vector of indices to use for baseline calculation
#' @export
calculate_baseline <- function(i, n, lookback, lookahead) {
  # Input validation - check types and lengths first
  validate_numeric_scalar(i, name = "i")
  validate_numeric_scalar(n, name = "n")
  validate_numeric_scalar(lookback, name = "lookback")
  validate_numeric_scalar(lookahead, name = "lookahead")

  # Check individual parameter constraints
  validate_positive(n, name = "n")
  validate_positive(lookback, name = "lookback")
  validate_positive(lookahead, name = "lookahead")

  # Now check cross-parameter constraints (i vs n)
  if (i < 1 || i > n) {
    stop(paste0(
      "Argument 'i' must be integer between 1 and ",
      n,
      ", received: ",
      toString(i)
    ))
  }

  # Convert to integer for indexing
  i <- as.integer(i)
  n <- as.integer(n)
  lookback <- as.integer(lookback)
  lookahead <- as.integer(lookahead)

  # Define window around current point
  window_start <- max(1, i - lookback)
  window_end <- min(n, i + lookahead)

  # Calculate baseline indices, excluding current point and immediate neighbors
  baseline_indices <- integer(0)

  # Add lookback indices if valid range exists
  if (window_start <= (i - 2)) {
    baseline_indices <- c(baseline_indices, window_start:(i - 2))
  }

  # Add lookahead indices if valid range exists
  if ((i + 2) <= window_end) {
    baseline_indices <- c(baseline_indices, (i + 2):window_end)
  }

  # Filter to ensure all indices are within bounds (defensive programming)
  baseline_indices <- baseline_indices[
    baseline_indices > 0 & baseline_indices <= n
  ]

  baseline_indices
}
