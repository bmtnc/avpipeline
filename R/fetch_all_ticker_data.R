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
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")
  validate_numeric_scalar(delay_seconds, name = "delay_seconds", gte = 0)

  api_log <- tibble::tibble(
    ticker = character(),
    endpoint = character(),
    status_message = character()
  )

  fetch_with_logging <- function(endpoint_name, fetch_fn) {
    tryCatch(
      {
        result <- fetch_fn()
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

  balance_sheet <- fetch_with_logging(
    "balance_sheet",
    function() fetch_balance_sheet(ticker)
  )
  Sys.sleep(delay_seconds)

  income_statement <- fetch_with_logging(
    "income_statement",
    function() fetch_income_statement(ticker)
  )
  Sys.sleep(delay_seconds)

  cash_flow <- fetch_with_logging(
    "cash_flow",
    function() fetch_cash_flow(ticker)
  )
  Sys.sleep(delay_seconds)

  earnings <- fetch_with_logging(
    "earnings",
    function() fetch_earnings(ticker)
  )
  Sys.sleep(delay_seconds)

  price_data <- fetch_with_logging(
    "price_data",
    function() fetch_price(ticker, outputsize = "full")
  )
  Sys.sleep(delay_seconds)

  splits_data <- fetch_with_logging(
    "splits_data",
    function() fetch_splits(ticker)
  )

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
