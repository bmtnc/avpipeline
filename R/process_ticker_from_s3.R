#' Process TTM Pipeline for Single Ticker from S3
#'
#' Reads raw data from S3 and processes through TTM pipeline.
#'
#' @param ticker character: Stock ticker symbol
#' @param bucket_name character: S3 bucket name
#' @param start_date Date: Start date for filtering financial data
#' @param region character: AWS region (default: "us-east-1")
#' @param threshold numeric: Z-score threshold for anomaly detection (default: 4)
#' @param lookback integer: Lookback for anomaly detection (default: 5)
#' @param lookahead integer: Lookahead for anomaly detection (default: 5)
#' @param end_window_size integer: Window size for end-of-series detection (default: 5)
#' @param end_threshold numeric: Threshold for end-of-series detection (default: 3)
#' @param min_obs integer: Minimum observations for anomaly detection (default: 10)
#' @return tibble or NULL: TTM per-share financial data
#' @keywords internal
process_ticker_from_s3 <- function(
  ticker,
  bucket_name,
  start_date,
  region = "us-east-1",
  threshold = 4,
  lookback = 5,
  lookahead = 5,
  end_window_size = 5,
  end_threshold = 3,
  min_obs = 10
) {
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("process_ticker_from_s3(): [ticker] must be a character scalar")
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("process_ticker_from_s3(): [bucket_name] must be a character scalar")
  }
  if (!inherits(start_date, "Date")) {
    stop("process_ticker_from_s3(): [start_date] must be a Date object")
  }

  raw_data <- s3_read_ticker_raw_data(ticker, bucket_name, region)

  balance_sheet <- raw_data$balance_sheet
  income_statement <- raw_data$income_statement
  cash_flow <- raw_data$cash_flow
  earnings <- raw_data$earnings
  price_data <- raw_data$price
  splits_data <- raw_data$splits

  if (is.null(earnings) || nrow(earnings) == 0) {
    return(NULL)
  }
  if (is.null(price_data) || nrow(price_data) == 0) {
    return(NULL)
  }

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

  if (nrow(financial_statements) == 0) {
    return(NULL)
  }

  market_cap <- build_market_cap_with_splits(
    price_data = price_data,
    splits_data = splits_data,
    financial_statements = financial_statements,
    start_date = start_date
  )

  calculate_unified_ttm_per_share_metrics(
    financial_statements = financial_statements,
    price_data = price_data,
    market_cap = market_cap
  )
}
