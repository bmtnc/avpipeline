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
  validate_non_empty(metric_cols, name = "metric_cols")
  if (!is.character(metric_cols)) {
    stop(paste0(
      "Argument 'metric_cols' must be non-empty character vector, received: ",
      class(metric_cols)[1],
      " of length ",
      length(metric_cols)
    ))
  }

  validate_character_scalar(date_col, allow_empty = FALSE, name = "date_col")
  validate_character_scalar(ticker_col, allow_empty = FALSE, name = "ticker_col")
  validate_df_type(data)

  if (nrow(data) == 0) {
    return(data)
  }

  required_cols <- c(ticker_col, date_col, metric_cols)
  validate_df_cols(data, required_cols)

  validate_positive(threshold, name = "threshold")
  validate_numeric_scalar(lookback, name = "lookback", gte = 1)
  validate_numeric_scalar(lookahead, name = "lookahead", gte = 1)

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
