#' Clean All Statement Anomalies
#'
#' Orchestrates anomaly cleaning for all 3 financial statements using configuration-based loop.
#'
#' @param statements list: Named list with cash_flow, income_statement, balance_sheet
#' @param threshold numeric: Percentage change threshold for quarterly cleaning
#' @param lookback numeric: Number of quarters to look back
#' @param lookahead numeric: Number of quarters to look ahead
#' @param end_window_size numeric: Size of end window for anomaly detection
#' @param end_threshold numeric: Percentage change threshold for end-window cleaning
#' @param min_obs numeric: Minimum observations required per ticker
#' @return list: Named list with cleaned cash_flow, income_statement, balance_sheet
#' @keywords internal
clean_all_statement_anomalies <- function(
  statements,
  threshold = 4,
  lookback = 5,
  lookahead = 5,
  end_window_size = 5,
  end_threshold = 3,
  min_obs = 10
) {
  if (!is.list(statements)) {
    stop(paste0(
      "clean_all_statement_anomalies(): [statements] must be a list, not ",
      class(statements)[1]
    ))
  }

  required_names <- c("cash_flow", "income_statement", "balance_sheet")
  missing_names <- setdiff(required_names, names(statements))
  if (length(missing_names) > 0) {
    stop(paste0(
      "clean_all_statement_anomalies(): [statements] must contain: ",
      paste(required_names, collapse = ", ")
    ))
  }

  validate_positive(threshold, name = "threshold")

  metadata_cols <- c(
    "ticker",
    "fiscalDateEnding",
    "reportedCurrency",
    "as_of_date"
  )

  statement_configs <- list(
    list(
      name = "income_statement",
      display_name = "Income statement",
      data = statements$income_statement
    ),
    list(
      name = "cash_flow",
      display_name = "Cash flow",
      data = statements$cash_flow
    ),
    list(
      name = "balance_sheet",
      display_name = "Balance sheet",
      data = statements$balance_sheet
    )
  )

  cleaned_statements <- list()

  for (config in statement_configs) {
    metrics <- setdiff(names(config$data), metadata_cols)

    cleaned_statements[[config$name]] <- clean_single_statement_anomalies(
      data = config$data,
      metrics = metrics,
      statement_name = config$display_name,
      threshold = threshold,
      lookback = lookback,
      lookahead = lookahead,
      end_window_size = end_window_size,
      end_threshold = end_threshold,
      min_obs = min_obs
    )
  }

  cleaned_statements
}
