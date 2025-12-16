#' Process Complete TTM Pipeline for Single Ticker
#'
#' Orchestrates all pipeline stages for a single ticker: fetch financial data,
#' clean statements, calculate market cap with split adjustments, compute TTM
#' metrics, forward-fill financial data, and calculate per-share metrics.
#' This function processes one ticker completely in memory before returning.
#'
#' @param ticker character: Stock ticker symbol (e.g., "AAPL")
#' @param start_date Date: Start date for filtering financial data
#' @param threshold numeric: Z-score threshold for anomaly detection (default 4)
#' @param lookback integer: Number of observations to look back for anomaly detection (default 5)
#' @param lookahead integer: Number of observations to look ahead for anomaly detection (default 5)
#' @param end_window_size integer: Window size for end-of-series anomaly detection (default 5)
#' @param end_threshold numeric: Threshold for end-of-series anomaly detection (default 3)
#' @param min_obs integer: Minimum observations required for anomaly detection (default 10)
#' @param delay_seconds numeric: API delay between requests in seconds (default 1)
#' @return list: Contains 'data' (tibble with TTM per-share financial data) and 'api_log' (tibble with API call status)
#' @keywords internal
process_single_ticker <- function(
  ticker,
  start_date,
  threshold = 4,
  lookback = 5,
  lookahead = 5,
  end_window_size = 5,
  end_threshold = 3,
  min_obs = 10,
  delay_seconds = 1
) {
  # Input validation
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")
  validate_date_type(start_date, scalar = TRUE, name = "start_date")
  validate_positive(threshold, name = "threshold")
  validate_numeric_scalar(delay_seconds, name = "delay_seconds", gte = 0)
  
  # ============================================================================
  # FETCH ALL DATA
  # ============================================================================
  
  all_data <- fetch_all_ticker_data(ticker, delay_seconds)
  
  # Extract components
  balance_sheet <- all_data$balance_sheet
  income_statement <- all_data$income_statement
  cash_flow <- all_data$cash_flow
  earnings <- all_data$earnings
  price_data <- all_data$price_data
  splits_data <- all_data$splits_data
  api_log <- all_data$api_log
  
  # Check if we have minimal data (earnings and price required)
  if (nrow(earnings) == 0 || nrow(price_data) == 0) {
    return(list(data = NULL, api_log = api_log))
  }
  
  # ============================================================================
  # VALIDATE AND PREPARE FINANCIAL STATEMENTS
  # ============================================================================
  
  financial_statements <- validate_and_prepare_statements(
    cash_flow = cash_flow,
    income_statement = income_statement,
    balance_sheet = balance_sheet,
    earnings = earnings,
    threshold = threshold,
    lookback = lookback,
    lookahead = lookahead,
    end_window_size = end_window_size,
    end_threshold = end_threshold,
    min_obs = min_obs
  )
  
  # Check if we have financial data after cleaning
  if (nrow(financial_statements) == 0) {
    return(list(data = NULL, api_log = api_log))
  }
  
  # ============================================================================
  # BUILD MARKET CAP WITH SPLIT ADJUSTMENT
  # ============================================================================
  
  market_cap <- build_market_cap_with_splits(
    price_data = price_data,
    splits_data = splits_data,
    financial_statements = financial_statements,
    start_date = start_date
  )
  
  # ============================================================================
  # CALCULATE TTM METRICS AND PER-SHARE VALUES
  # ============================================================================
  
  ttm_per_share_data <- calculate_unified_ttm_per_share_metrics(
    financial_statements = financial_statements,
    price_data = price_data,
    market_cap = market_cap
  )
  
  list(data = ttm_per_share_data, api_log = api_log)
}
