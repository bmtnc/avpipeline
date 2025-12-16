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
  if (!is.character(metric_cols) || length(metric_cols) == 0) {
    stop(paste0(
      "Argument 'metric_cols' must be non-empty character vector, received: ",
      class(metric_cols)[1],
      " of length ",
      length(metric_cols)
    ))
  }

  # Validate data frame and required columns
  validate_df_cols(data, metric_cols)

  if (!is.numeric(threshold) || length(threshold) != 1 || threshold <= 0) {
    stop(paste0(
      "Argument 'threshold' must be positive numeric, received: ",
      threshold
    ))
  }

  if (!is.numeric(lookback) || length(lookback) != 1 || lookback < 1) {
    stop(paste0(
      "Argument 'lookback' must be positive integer, received: ",
      lookback
    ))
  }

  if (!is.numeric(lookahead) || length(lookahead) != 1 || lookahead < 1) {
    stop(paste0(
      "Argument 'lookahead' must be positive integer, received: ",
      lookahead
    ))
  }

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
          cat(
            "Failed to detect anomalies for ticker '",
            ticker_name,
            "' column '",
            col,
            "'. Error: ",
            e$message,
            "\n"
          )
          # Return FALSE vector as fallback for this ticker-column
          rep(FALSE, nrow(ticker_data))
        }
      )

      # Add the anomaly column (either successful detection or FALSE fallback)
      result[[anomaly_col]] <- anomaly_flags
    }

    result
  })

  # Bind results back together
  dplyr::bind_rows(processed_list)
}
