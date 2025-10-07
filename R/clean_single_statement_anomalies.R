#' Clean Single Statement Anomalies
#'
#' Cleans one statement type using both quarterly and end-window cleaning.
#'
#' @param data data.frame: Financial statement data
#' @param metrics character: Vector of metric column names to clean
#' @param statement_name character: Name of statement for logging
#' @param threshold numeric: Percentage change threshold for quarterly cleaning
#' @param lookback numeric: Number of quarters to look back
#' @param lookahead numeric: Number of quarters to look ahead
#' @param end_window_size numeric: Size of end window for anomaly detection
#' @param end_threshold numeric: Percentage change threshold for end-window cleaning
#' @param min_obs numeric: Minimum observations required per ticker
#' @return data.frame: Cleaned financial statement data
#' @keywords internal
clean_single_statement_anomalies <- function(data, metrics, statement_name,
                                            threshold = 4, lookback = 5, lookahead = 5,
                                            end_window_size = 5, end_threshold = 3, min_obs = 10) {
  if (!is.data.frame(data)) {
    stop(paste0("clean_single_statement_anomalies(): [data] must be a data.frame, not ", class(data)[1]))
  }
  if (!is.character(metrics)) {
    stop(paste0("clean_single_statement_anomalies(): [metrics] must be a character vector, not ", class(metrics)[1]))
  }
  if (!is.character(statement_name) || length(statement_name) != 1) {
    stop(paste0("clean_single_statement_anomalies(): [statement_name] must be a character scalar, not ", class(statement_name)[1], " of length ", length(statement_name)))
  }
  if (!is.numeric(threshold) || length(threshold) != 1 || threshold <= 0) {
    stop(paste0("clean_single_statement_anomalies(): [threshold] must be a positive numeric scalar, not ", class(threshold)[1]))
  }
  if (!is.numeric(min_obs) || length(min_obs) != 1 || min_obs <= 0) {
    stop(paste0("clean_single_statement_anomalies(): [min_obs] must be a positive numeric scalar, not ", class(min_obs)[1]))
  }

  message(paste0("Cleaning ", statement_name, " metrics..."))

  data_filtered <- filter_sufficient_observations(data, "ticker", min_obs)

  if (nrow(data_filtered) == 0) {
    message(paste0("⚠ No ", statement_name, " data with sufficient observations"))
    return(data)
  }

  data_cleaned <- tryCatch({
    clean_quarterly_metrics(
      data = data_filtered,
      metric_cols = metrics,
      date_col = "fiscalDateEnding",
      ticker_col = "ticker",
      threshold = threshold,
      lookback = lookback,
      lookahead = lookahead
    )
  }, error = function(e) {
    message(paste0(statement_name, " quarterly cleaning failed, keeping original data. Error: ", e$message))
    return(data)
  })

  data_cleaned <- tryCatch({
    data_cleaned %>%
      dplyr::group_by(ticker) %>%
      dplyr::arrange(ticker, fiscalDateEnding) %>%
      clean_end_window_anomalies(
        metric_cols = metrics,
        end_window_size = end_window_size,
        threshold = end_threshold,
        min_observations = min_obs
      ) %>%
      dplyr::ungroup()
  }, error = function(e) {
    message(paste0(statement_name, " end-window cleaning failed, keeping stage 1 data. Error: ", e$message))
    return(data_cleaned)
  })

  message(paste0("✓ ", statement_name, " cleaned successfully"))

  data_cleaned
}
