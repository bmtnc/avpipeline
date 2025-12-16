test_that("get_financial_statement_tickers returns manual tickers when provided", {
  manual_tickers <- c("AAPL", "MSFT", "GOOGL")
  
  result <- suppressMessages(get_financial_statement_tickers(manual_tickers = manual_tickers))
  
  expect_equal(result, manual_tickers)
  expect_type(result, "character")
  expect_length(result, 3)
})

test_that("get_financial_statement_tickers prefers manual tickers over ETF", {
  manual_tickers <- c("AAPL", "MSFT")
  
  result <- suppressMessages(get_financial_statement_tickers(
    etf_symbol = "SPY",
    manual_tickers = manual_tickers
  ))
  
  expect_equal(result, manual_tickers)
})

test_that("get_financial_statement_tickers validates at least one parameter provided", {
  expect_error(
    get_financial_statement_tickers(),
    "^get_financial_statement_tickers\\(\\): At least one of \\[etf_symbol\\] or \\[manual_tickers\\] must be provided$"
  )
})

test_that("get_financial_statement_tickers validates etf_symbol is character scalar", {
  expect_error(
    get_financial_statement_tickers(etf_symbol = 123),
    "^etf_symbol must be a character scalar \\(length 1\\)\\. Received: numeric of length 1$"
  )

  expect_error(
    get_financial_statement_tickers(etf_symbol = c("SPY", "IWB")),
    "^etf_symbol must be a character scalar \\(length 1\\)\\. Received: character of length 2$"
  )
})

test_that("get_financial_statement_tickers validates manual_tickers is character", {
  expect_error(
    get_financial_statement_tickers(manual_tickers = 123),
    "^get_financial_statement_tickers\\(\\): \\[manual_tickers\\] must be a character vector, not numeric$"
  )
  
  expect_error(
    get_financial_statement_tickers(manual_tickers = list("AAPL")),
    "^get_financial_statement_tickers\\(\\): \\[manual_tickers\\] must be a character vector, not list$"
  )
})

test_that("get_financial_statement_tickers handles single manual ticker", {
  result <- suppressMessages(get_financial_statement_tickers(manual_tickers = "AAPL"))
  
  expect_equal(result, "AAPL")
  expect_length(result, 1)
})
