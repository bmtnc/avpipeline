#' Add Anomaly Flag Columns to Quarterly Data
#'
#' Applies temporary anomaly detection to multiple metric columns and adds corresponding
#' anomaly flag columns. Handles failures gracefully at the ticker-column level by keeping
#' original data for failed ticker-column combinations.
#'
#' @param data Data frame with quarterly financial data
#' @param metric_cols Character vector of column names to analyze for anomalies
#' @param threshold Numeric threshold multiplier for MAD detection
#' @param lookback Integer number of periods to look back for baseline calculation
#' @param lookahead Integer number of periods to look ahead for baseline calculation
#' @return Data frame with original data plus anomaly flag columns ending in "_anomaly"
#' @export
add_anomaly_flag_columns <- function(
  data,
  metric_cols,
  threshold = 3,
  lookback = 4,
  lookahead = 4
) {
  # Input validation
  validate_non_empty(metric_cols, name = "metric_cols")
  if (!is.character(metric_cols)) {
    stop(paste0(
      "Argument 'metric_cols' must be non-empty character vector, received: ",
      class(metric_cols)[1],
      " of length ",
      length(metric_cols)
    ))
  }

  # Validate data frame and required columns
  validate_df_cols(data, metric_cols)

  validate_positive(threshold, name = "threshold")
  validate_positive(lookback, name = "lookback")
  validate_positive(lookahead, name = "lookahead")

  # Check if ticker column exists
  if (!"ticker" %in% names(data)) {
    stop("Data must contain 'ticker' column for ticker-level error handling")
  }

  # Split-apply-bind pattern for ticker-level error handling
  ticker_list <- split(data, data$ticker)

  # Apply anomaly detection to each ticker separately
  processed_list <- lapply(ticker_list, function(ticker_data) {
    ticker_name <- ticker_data$ticker[1]

    # Initialize result with original data
    result <- ticker_data
    failed_cols <- character(0)
    fail_reasons <- character(0)

    # Add anomaly flags for each metric column with error handling
    for (col in metric_cols) {
      anomaly_col <- paste0(col, "_anomaly")

      # Try to detect anomalies, with fallback to FALSE if it fails
      anomaly_flags <- tryCatch(
        {
          detect_temporary_anomalies(
            ticker_data[[col]],
            lookback = lookback,
            lookahead = lookahead,
            threshold = threshold
          )
        },
        error = function(e) {
          failed_cols <<- c(failed_cols, col)
          fail_reasons <<- c(fail_reasons, e$message)
          # Return FALSE vector as fallback for this ticker-column
          rep(FALSE, nrow(ticker_data))
        }
      )

      # Add the anomaly column (either successful detection or FALSE fallback)
      result[[anomaly_col]] <- anomaly_flags
    }

    # Log one summary line per ticker if any columns failed
    if (length(failed_cols) > 0) {
      unique_reasons <- unique(fail_reasons)
      cat(sprintf(
        "Anomaly detection skipped for ticker '%s' (%d/%d columns): %s\n",
        ticker_name, length(failed_cols), length(metric_cols),
        paste(unique_reasons, collapse = "; ")
      ))
    }

    result
  })

  # Bind results back together
  dplyr::bind_rows(processed_list)
}
