#' Price Data Configuration
#'
#' Configuration object for fetching daily adjusted price data from Alpha Vantage.
#'
#' @format A list containing configuration parameters for price data fetching.
#' @export
#' @examples
#' \dontrun{
#' # Fetch price data
#' price_data <- fetch_single_ticker_data("AAPL", PRICE_CONFIG)
#' }
PRICE_CONFIG <- list(
  api_function = "TIME_SERIES_DAILY_ADJUSTED",
  parser_func = "parse_price_response",
  additional_params = c("outputsize", "datatype"),
  default_delay = 1,
  data_type_name = "price",
  primary_date_column = "date",
  cache_date_columns = c("date", "initial_date", "latest_date", "as_of_date"),
  result_sort_columns = c("ticker", "date"),
  default_outputsize = "compact",
  default_datatype = "json"
)

#' Income Statement Data Configuration
#'
#' Configuration object for fetching quarterly income statement data from Alpha Vantage.
#'
#' @format A list containing configuration parameters for income statement data fetching.
#' @export
INCOME_STATEMENT_CONFIG <- list(
  api_function = "INCOME_STATEMENT",
  parser_func = "parse_income_statement_response",
  additional_params = c(),
  default_delay = 1,
  data_type_name = "income statement",
  primary_date_column = "fiscalDateEnding",
  cache_date_columns = c("fiscalDateEnding", "as_of_date"),
  result_sort_columns = c("ticker", "fiscalDateEnding"),
  sort_desc = TRUE
)

#' Balance Sheet Data Configuration
#'
#' Configuration object for fetching quarterly balance sheet data from Alpha Vantage.
#'
#' @format A list containing configuration parameters for balance sheet data fetching.
#' @export
BALANCE_SHEET_CONFIG <- list(
  api_function = "BALANCE_SHEET",
  parser_func = "parse_balance_sheet_response",
  additional_params = c(),
  default_delay = 1,
  data_type_name = "balance sheet",
  primary_date_column = "fiscalDateEnding",
  cache_date_columns = c("fiscalDateEnding", "as_of_date"),
  result_sort_columns = c("ticker", "fiscalDateEnding"),
  sort_desc = TRUE
)

#' Cash Flow Data Configuration
#'
#' Configuration object for fetching quarterly cash flow data from Alpha Vantage.
#'
#' @format A list containing configuration parameters for cash flow data fetching.
#' @export
CASH_FLOW_CONFIG <- list(
  api_function = "CASH_FLOW",
  parser_func = "parse_cash_flow_response",
  additional_params = c(),
  default_delay = 1,
  data_type_name = "cash flow",
  primary_date_column = "fiscalDateEnding",
  cache_date_columns = c("fiscalDateEnding", "as_of_date"),
  result_sort_columns = c("ticker", "fiscalDateEnding"),
  sort_desc = TRUE
)

#' Earnings Data Configuration
#'
#' Configuration object for fetching quarterly earnings data from Alpha Vantage.
#' This data provides timing metadata for when financial statements were reported.
#'
#' @format A list containing configuration parameters for earnings data fetching.
#' @export
EARNINGS_CONFIG <- list(
  api_function = "EARNINGS",
  parser_func = "parse_earnings_response",
  additional_params = c(),
  default_delay = 1,
  data_type_name = "earnings",
  primary_date_column = "fiscalDateEnding",
  cache_date_columns = c("fiscalDateEnding", "reportedDate", "as_of_date"),
  result_sort_columns = c("ticker", "fiscalDateEnding"),
  sort_desc = TRUE
)

#' ETF Profile Data Configuration
#'
#' Configuration object for fetching ETF profile data from Alpha Vantage.
#'
#' @format A list containing configuration parameters for ETF profile data fetching.
#' @export
ETF_PROFILE_CONFIG <- list(
  api_function = "ETF_PROFILE",
  parser_func = "parse_etf_profile_response",
  additional_params = c(),
  default_delay = 1,
  data_type_name = "ETF profile",
  primary_date_column = NULL,
  cache_date_columns = c("as_of_date"),
  result_sort_columns = c("symbol"),
  sort_desc = FALSE
)

#' Corporate Actions - Splits Data Configuration
#'
#' Configuration object for fetching historical stock split events from Alpha Vantage.
#'
#' @format A list containing configuration parameters for splits data fetching.
#' @export
SPLITS_CONFIG <- list(
  api_function = "SPLITS",
  parser_func = "parse_splits_response",
  additional_params = c(),
  default_delay = 1,
  data_type_name = "splits",
  primary_date_column = "effective_date",
  cache_date_columns = c("effective_date", "as_of_date"),
  result_sort_columns = c("ticker", "effective_date"),
  sort_desc = FALSE
)

