#' Fetch All Data Types for a Single Ticker
#'
#' Orchestrates fetching of all required data types from Alpha Vantage API
#' for a single ticker: balance sheet, income statement, cash flow, earnings,
#' price data, and splits. Handles API errors gracefully and logs all requests.
#'
#' @param ticker character: Stock ticker symbol (e.g., "AAPL")
#' @param delay_seconds numeric: API delay between requests in seconds (default 1)
#' @return list: Contains 6 data tibbles (balance sheet, income, cash flow, earnings, price, splits) plus API log
#' @keywords internal
fetch_all_ticker_data <- function(
  ticker,
  delay_seconds = 1
) {
  if (!is.character(ticker) || length(ticker) != 1 || nchar(ticker) == 0) {
    stop(paste0(
      "fetch_all_ticker_data(): [ticker] must be a non-empty character scalar, not ",
      class(ticker)[1],
      " of length ",
      length(ticker)
    ))
  }
  if (
    !is.numeric(delay_seconds) ||
      length(delay_seconds) != 1 ||
      delay_seconds < 0
  ) {
    stop(paste0(
      "fetch_all_ticker_data(): [delay_seconds] must be a non-negative numeric scalar, not ",
      class(delay_seconds)[1],
      " of length ",
      length(delay_seconds)
    ))
  }

  # Initialize API log
  api_log <- tibble::tibble(
    ticker = character(),
    endpoint = character(),
    status_message = character()
  )

  # Helper function to fetch with error handling and logging
  fetch_with_logging <- function(endpoint_name, config, ...) {
    tryCatch(
      {
        result <- fetch_single_ticker_data(ticker, config, ...)
        api_log <<- dplyr::bind_rows(
          api_log,
          tibble::tibble(
            ticker = ticker,
            endpoint = endpoint_name,
            status_message = "successful"
          )
        )
        result
      },
      error = function(e) {
        api_log <<- dplyr::bind_rows(
          api_log,
          tibble::tibble(
            ticker = ticker,
            endpoint = endpoint_name,
            status_message = paste0("Error: ", conditionMessage(e))
          )
        )
        tibble::tibble()
      }
    )
  }

  # Fetch balance sheet
  balance_sheet <- fetch_with_logging(
    "balance_sheet",
    BALANCE_SHEET_CONFIG,
    datatype = "json"
  )
  Sys.sleep(delay_seconds)

  # Fetch income statement
  income_statement <- fetch_with_logging(
    "income_statement",
    INCOME_STATEMENT_CONFIG,
    datatype = "json"
  )
  Sys.sleep(delay_seconds)

  # Fetch cash flow
  cash_flow <- fetch_with_logging(
    "cash_flow",
    CASH_FLOW_CONFIG,
    datatype = "json"
  )
  Sys.sleep(delay_seconds)

  # Fetch earnings
  earnings <- fetch_with_logging("earnings", EARNINGS_CONFIG, datatype = "json")
  Sys.sleep(delay_seconds)

  # Fetch price data
  price_data <- fetch_with_logging(
    "price_data",
    PRICE_CONFIG,
    outputsize = "full",
    datatype = "json"
  )
  Sys.sleep(delay_seconds)

  # Fetch splits data (last call, no delay after)
  splits_data <- fetch_with_logging("splits_data", SPLITS_CONFIG)

  # Return all data and log
  list(
    balance_sheet = balance_sheet,
    income_statement = income_statement,
    cash_flow = cash_flow,
    earnings = earnings,
    price_data = price_data,
    splits_data = splits_data,
    api_log = api_log
  )
}
