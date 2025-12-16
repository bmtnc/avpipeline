#' Clean End-Window Anomalies Using Percentage Change Detection
#'
#' Applies a second stage of anomaly detection specifically targeting anomalies
#' in the end window of time series data. Calculates quarter-over-quarter percentage
#' changes, detects anomalies using MAD threshold, and only flags anomalies occurring
#' in the last N observations. Replaces flagged anomalies with forward-filled values.
#'
#' @param data Data frame with cleaned quarterly financial data (grouped by ticker)
#' @param metric_cols Character vector of column names to analyze for end-window anomalies
#' @param end_window_size Integer number of observations at the end to check for anomalies
#' @param threshold Numeric threshold multiplier for MAD detection on percentage changes
#' @param min_observations Integer minimum number of observations required for anomaly detection
#' @return Data frame with end-window anomalies cleaned via forward fill
#' @export
clean_end_window_anomalies <- function(
  data,
  metric_cols,
  end_window_size = 5,
  threshold = 3,
  min_observations = 10
) {
  # Input validation for metric_cols
  if (!is.character(metric_cols) || length(metric_cols) == 0) {
    stop(paste0(
      "Argument 'metric_cols' must be non-empty character vector, received: ",
      class(metric_cols)[1],
      " of length ",
      length(metric_cols)
    ))
  }

  # Validate data frame and required columns
  required_cols <- c("ticker", metric_cols)
  validate_df_cols(data, required_cols)

  # Input validation for numeric parameters
  if (
    !is.numeric(end_window_size) ||
      length(end_window_size) != 1 ||
      end_window_size < 1
  ) {
    stop(paste0(
      "Argument 'end_window_size' must be positive integer, received: ",
      end_window_size
    ))
  }

  if (!is.numeric(threshold) || length(threshold) != 1 || threshold <= 0) {
    stop(paste0(
      "Argument 'threshold' must be positive numeric, received: ",
      threshold
    ))
  }

  if (
    !is.numeric(min_observations) ||
      length(min_observations) != 1 ||
      min_observations < 1
  ) {
    stop(paste0(
      "Argument 'min_observations' must be positive integer, received: ",
      min_observations
    ))
  }

  # Convert to integers
  end_window_size <- as.integer(end_window_size)
  min_observations <- as.integer(min_observations)

  # Handle empty data gracefully
  if (nrow(data) == 0) {
    return(data)
  }

  # Split-apply-combine pattern for ticker-level processing
  ticker_list <- split(data, data$ticker)

  # Process each ticker separately with error handling
  processed_list <- lapply(ticker_list, function(ticker_data) {
    ticker_name <- ticker_data$ticker[1]

    # Check if ticker has sufficient observations
    if (nrow(ticker_data) < min_observations) {
      return(ticker_data) # Skip cleaning if insufficient data
    }

    # Initialize result with original data
    result <- ticker_data

    # Process each metric column
    for (col in metric_cols) {
      tryCatch(
        {
          # Skip if column has all NA values
          if (all(is.na(ticker_data[[col]]))) {
            next
          }

          # Calculate quarter-over-quarter percentage changes
          values <- ticker_data[[col]]
          pct_changes <- c(
            NA,
            diff(values) / abs(values[-length(values)]) * 100
          )

          # Skip if not enough non-NA percentage changes
          valid_pct_changes <- pct_changes[!is.na(pct_changes)]
          if (length(valid_pct_changes) < min_observations) {
            next
          }

          # Detect anomalies in percentage changes
          anomaly_flags <- detect_time_series_anomalies(
            valid_pct_changes,
            threshold = threshold,
            min_observations = min_observations
          )

          # Map anomaly flags back to original positions (accounting for NA in first position)
          full_anomaly_flags <- rep(FALSE, nrow(ticker_data))
          full_anomaly_flags[2:length(full_anomaly_flags)] <- anomaly_flags

          # Only keep anomaly flags in the end window
          end_start_idx <- max(1, nrow(ticker_data) - end_window_size + 1)
          end_window_flags <- rep(FALSE, nrow(ticker_data))
          end_window_flags[end_start_idx:nrow(ticker_data)] <-
            full_anomaly_flags[end_start_idx:nrow(ticker_data)]

          # Replace end-window anomalies with NA and forward fill
          if (any(end_window_flags)) {
            cleaned_values <- ifelse(end_window_flags, NA, values)
            result[[col]] <- zoo::na.locf(cleaned_values, na.rm = FALSE)
          }
        },
        error = function(e) {
          warning(paste0(
            "Failed to clean end-window anomalies for ticker '",
            ticker_name,
            "' column '",
            col,
            "'. Error: ",
            e$message
          ))
          # Keep original data for this column if cleaning fails
        }
      )
    }

    result
  })

  # Bind results back together
  dplyr::bind_rows(processed_list)
}
