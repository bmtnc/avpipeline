#' Detect Temporary Anomalies Using Lookback/Lookahead Baseline
#'
#' Identifies temporary anomalies in time series data using a baseline calculated from
#' surrounding observations. For each point, establishes a baseline from lookback and
#' lookahead windows (excluding immediate neighbors to prevent contamination), then
#' flags points that deviate significantly from this baseline using MAD threshold.
#'
#' @param values Numeric vector of time series values to analyze for anomalies
#' @param lookback Integer number of periods to look back for baseline calculation
#' @param lookahead Integer number of periods to look ahead for baseline calculation
#' @param threshold Numeric threshold multiplier for MAD (Median Absolute Deviation) detection
#' @return Logical vector of same length as values, TRUE indicates anomalous observation
#' @export
detect_temporary_anomalies <- function(
  values,
  lookback = 4,
  lookahead = 4,
  threshold = 3
) {
  validate_numeric_vector(values, allow_empty = FALSE, name = "values")
  validate_numeric_scalar(lookback, name = "lookback", gte = 1)
  validate_numeric_scalar(lookahead, name = "lookahead", gte = 1)
  validate_positive(threshold, name = "threshold")

  # Convert to integer for indexing
  lookback <- as.integer(lookback)
  lookahead <- as.integer(lookahead)

  # Check minimum data requirements
  min_required_length <- lookback + lookahead + 3 # +3 for current point and 2 exclusions
  if (length(values) < min_required_length) {
    stop(paste0(
      "Insufficient data: need at least ",
      min_required_length,
      " observations for lookback=",
      lookback,
      " and lookahead=",
      lookahead,
      ", received: ",
      length(values)
    ))
  }

  # Use vapply to detect anomalies for each position
  vapply(
    seq_along(values),
    detect_single_baseline_anomaly,
    logical(1),
    values,
    lookback,
    lookahead,
    threshold
  )
}
