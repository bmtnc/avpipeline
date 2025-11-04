#' Validate and Prepare Financial Statements
#'
#' Orchestrates the complete data cleaning and validation pipeline for financial
#' statements. Removes invalid data, detects anomalies, aligns tickers and dates,
#' joins statements with earnings timing, and standardizes to calendar quarters.
#'
#' @param cash_flow tibble: Quarterly cash flow statements
#' @param income_statement tibble: Quarterly income statements
#' @param balance_sheet tibble: Quarterly balance sheets
#' @param earnings tibble: Earnings timing metadata
#' @param threshold numeric: Z-score threshold for anomaly detection (default 4)
#' @param lookback integer: Number of observations to look back for anomaly detection (default 5)
#' @param lookahead integer: Number of observations to look ahead for anomaly detection (default 5)
#' @param end_window_size integer: Window size for end-of-series anomaly detection (default 5)
#' @param end_threshold numeric: Threshold for end-of-series anomaly detection (default 3)
#' @param min_obs integer: Minimum observations required for anomaly detection (default 10)
#' @return tibble: Cleaned financial statements with quality flags and standardized calendar quarters
#' @keywords internal
validate_and_prepare_statements <- function(
  cash_flow,
  income_statement,
  balance_sheet,
  earnings,
  threshold = 4,
  lookback = 5,
  lookahead = 5,
  end_window_size = 5,
  end_threshold = 3,
  min_obs = 10
) {
  # Input validation
  if (!is.numeric(threshold) || length(threshold) != 1 || threshold <= 0) {
    stop(paste0(
      "validate_and_prepare_statements(): [threshold] must be a positive numeric scalar, not ",
      class(threshold)[1], " of length ", length(threshold)
    ))
  }
  if (!is.numeric(lookback) || length(lookback) != 1 || lookback < 0) {
    stop(paste0(
      "validate_and_prepare_statements(): [lookback] must be a non-negative numeric scalar, not ",
      class(lookback)[1], " of length ", length(lookback)
    ))
  }
  if (!is.numeric(lookahead) || length(lookahead) != 1 || lookahead < 0) {
    stop(paste0(
      "validate_and_prepare_statements(): [lookahead] must be a non-negative numeric scalar, not ",
      class(lookahead)[1], " of length ", length(lookahead)
    ))
  }
  
  # Remove all-NA observations
  statements_cleaned <- remove_all_na_financial_observations(list(
    cash_flow = cash_flow,
    income_statement = income_statement,
    balance_sheet = balance_sheet
  ))
  
  # Detect and clean anomalies
  statements_cleaned <- clean_all_statement_anomalies(
    statements = statements_cleaned,
    threshold = threshold,
    lookback = lookback,
    lookahead = lookahead,
    end_window_size = end_window_size,
    end_threshold = end_threshold,
    min_obs = min_obs
  )
  
  # Align tickers across statements
  all_statements_aligned <- align_statement_tickers(list(
    earnings = earnings,
    cash_flow = statements_cleaned$cash_flow,
    income_statement = statements_cleaned$income_statement,
    balance_sheet = statements_cleaned$balance_sheet
  ))
  
  # Align dates across statements
  valid_dates <- align_statement_dates(list(
    cash_flow = all_statements_aligned$cash_flow,
    income_statement = all_statements_aligned$income_statement,
    balance_sheet = all_statements_aligned$balance_sheet
  ))
  
  # Join all financial statements
  financial_statements <- join_all_financial_statements(all_statements_aligned, valid_dates)
  
  # Return empty if no data
  if (nrow(financial_statements) == 0) {
    return(tibble::tibble())
  }
  
  # Add quality flags and filter columns
  financial_statements <- add_quality_flags(financial_statements)
  financial_statements <- filter_essential_financial_columns(financial_statements)
  
  # Validate quarterly continuity
  financial_statements <- validate_quarterly_continuity(financial_statements)
  
  # Standardize to calendar quarters
  financial_statements <- standardize_to_calendar_quarters(financial_statements)
  
  financial_statements
}
