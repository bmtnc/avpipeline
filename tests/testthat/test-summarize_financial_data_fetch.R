test_that("summarize_financial_data_fetch validates etf_symbol is character scalar or NULL", {
  tickers <- c("AAPL", "MSFT")
  data_list <- list(
    balance_sheet = data.frame(),
    cash_flow = data.frame(),
    income_statement = data.frame(),
    earnings = data.frame()
  )
  
  expect_error(
    summarize_financial_data_fetch(
      etf_symbol = 123,
      tickers = tickers,
      data_list = data_list
    ),
    "^etf_symbol must be a character scalar \\(length 1\\)\\. Received: numeric of length 1$"
  )

  expect_error(
    summarize_financial_data_fetch(
      etf_symbol = c("SPY", "IWB"),
      tickers = tickers,
      data_list = data_list
    ),
    "^etf_symbol must be a character scalar \\(length 1\\)\\. Received: character of length 2$"
  )
})

test_that("summarize_financial_data_fetch validates tickers is character", {
  data_list <- list(
    balance_sheet = data.frame(),
    cash_flow = data.frame(),
    income_statement = data.frame(),
    earnings = data.frame()
  )
  
  expect_error(
    summarize_financial_data_fetch(
      etf_symbol = "SPY",
      tickers = 123,
      data_list = data_list
    ),
    "^summarize_financial_data_fetch\\(\\): \\[tickers\\] must be a character vector, not numeric$"
  )
})

test_that("summarize_financial_data_fetch validates data_list is list", {
  expect_error(
    summarize_financial_data_fetch(
      etf_symbol = "SPY",
      tickers = c("AAPL", "MSFT"),
      data_list = "not a list"
    ),
    "^summarize_financial_data_fetch\\(\\): \\[data_list\\] must be a list, not character$"
  )
})

test_that("summarize_financial_data_fetch validates data_list has required keys", {
  incomplete_list <- list(
    balance_sheet = data.frame(),
    cash_flow = data.frame()
  )
  
  expect_error(
    summarize_financial_data_fetch(
      etf_symbol = "SPY",
      tickers = c("AAPL", "MSFT"),
      data_list = incomplete_list
    ),
    "^summarize_financial_data_fetch\\(\\): \\[data_list\\] must contain keys: balance_sheet, cash_flow, income_statement, earnings$"
  )
})

test_that("summarize_financial_data_fetch accepts valid inputs with ETF", {
  data_list <- list(
    balance_sheet = data.frame(),
    cash_flow = data.frame(),
    income_statement = data.frame(),
    earnings = data.frame()
  )
  
  expect_error(
    suppressMessages(summarize_financial_data_fetch(
      etf_symbol = "SPY",
      tickers = c("AAPL", "MSFT"),
      data_list = data_list
    )),
    NA
  )
})

test_that("summarize_financial_data_fetch accepts NULL etf_symbol", {
  data_list <- list(
    balance_sheet = data.frame(),
    cash_flow = data.frame(),
    income_statement = data.frame(),
    earnings = data.frame()
  )
  
  expect_error(
    suppressMessages(summarize_financial_data_fetch(
      etf_symbol = NULL,
      tickers = c("AAPL", "MSFT"),
      data_list = data_list
    )),
    NA
  )
})
