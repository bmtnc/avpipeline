#' Clean Quarterly Metrics with Temporary Anomaly Detection
#'
#' Applies temporary anomaly detection and cleaning to quarterly financial metrics.
#' Detects anomalies and replaces them with interpolated values. Data should be
#' pre-filtered for sufficient observations before calling this function.
#'
#' @param data Data frame with quarterly financial data
#' @param metric_cols Character vector of column names to clean
#' @param date_col Character string specifying the date column name
#' @param ticker_col Character string specifying the ticker column name
#' @param threshold Numeric threshold multiplier for MAD detection
#' @param lookback Integer number of periods to look back for baseline calculation
#' @param lookahead Integer number of periods to look ahead for baseline calculation
#' @return Data frame with cleaned metric columns and anomaly flag columns
#' @export
clean_quarterly_metrics <- function(
  data,
  metric_cols,
  date_col,
  ticker_col,
  threshold = 3,
  lookback = 4,
  lookahead = 4
) {
  if (!is.character(metric_cols) || length(metric_cols) == 0) {
    stop(paste0(
      "Argument 'metric_cols' must be non-empty character vector, received: ",
      class(metric_cols)[1],
      " of length ",
      length(metric_cols)
    ))
  }

  if (!is.character(date_col) || length(date_col) != 1) {
    stop(paste0(
      "Argument 'date_col' must be single character string, received: ",
      class(date_col)[1],
      " of length ",
      length(date_col)
    ))
  }

  if (!is.character(ticker_col) || length(ticker_col) != 1) {
    stop(paste0(
      "Argument 'ticker_col' must be single character string, received: ",
      class(ticker_col)[1],
      " of length ",
      length(ticker_col)
    ))
  }

  if (!is.data.frame(data)) {
    stop(paste0(
      "Argument 'data' must be data frame, received: ",
      class(data)[1]
    ))
  }

  if (nrow(data) == 0) {
    return(data)
  }

  required_cols <- c(ticker_col, date_col, metric_cols)
  validate_df_cols(data, required_cols)

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

  # Create symbols for NSE
  date_sym <- rlang::sym(date_col)
  ticker_sym <- rlang::sym(ticker_col)

  # Main cleaning pipeline
  tryCatch(
    {
      data %>%
        dplyr::select(!!ticker_sym, !!date_sym, dplyr::all_of(metric_cols)) %>%
        dplyr::distinct() %>%
        dplyr::arrange(!!ticker_sym, !!date_sym) %>%
        dplyr::group_by(!!ticker_sym) %>%
        add_anomaly_flag_columns(
          metric_cols,
          threshold,
          lookback,
          lookahead
        ) %>%
        clean_original_columns(metric_cols) %>%
        dplyr::ungroup()
    },
    error = function(e) {
      stop(paste0("Quarterly metrics cleaning failed. Error: ", e$message))
    }
  )
}
