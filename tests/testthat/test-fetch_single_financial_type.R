test_that("fetch_single_financial_type validates tickers is character", {
  expect_error(
    fetch_single_financial_type(
      tickers = 123,
      config = BALANCE_SHEET_CONFIG,
      cache_path = "cache/test.csv"
    ),
    "^fetch_single_financial_type\\(\\): \\[tickers\\] must be a character vector, not numeric$"
  )
  
  expect_error(
    fetch_single_financial_type(
      tickers = list("AAPL"),
      config = BALANCE_SHEET_CONFIG,
      cache_path = "cache/test.csv"
    ),
    "^fetch_single_financial_type\\(\\): \\[tickers\\] must be a character vector, not list$"
  )
})

test_that("fetch_single_financial_type validates config is list", {
  expect_error(
    fetch_single_financial_type(
      tickers = c("AAPL", "MSFT"),
      config = "not a list",
      cache_path = "cache/test.csv"
    ),
    "^fetch_single_financial_type\\(\\): \\[config\\] must be a list, not character$"
  )
  
  expect_error(
    fetch_single_financial_type(
      tickers = c("AAPL", "MSFT"),
      config = 123,
      cache_path = "cache/test.csv"
    ),
    "^fetch_single_financial_type\\(\\): \\[config\\] must be a list, not numeric$"
  )
})

test_that("fetch_single_financial_type validates cache_path is character scalar", {
  expect_error(
    fetch_single_financial_type(
      tickers = c("AAPL", "MSFT"),
      config = BALANCE_SHEET_CONFIG,
      cache_path = 123
    ),
    "^cache_path must be a character scalar \\(length 1\\)\\. Received: numeric of length 1$"
  )

  expect_error(
    fetch_single_financial_type(
      tickers = c("AAPL", "MSFT"),
      config = BALANCE_SHEET_CONFIG,
      cache_path = c("path1.csv", "path2.csv")
    ),
    "^cache_path must be a character scalar \\(length 1\\)\\. Received: character of length 2$"
  )
})

test_that("fetch_single_financial_type accepts valid inputs", {
  temp_dir <- tempdir()
  temp_file <- file.path(temp_dir, "test_fetch.csv")
  
  expect_error(
    suppressMessages(fetch_single_financial_type(
      tickers = c("AAPL"),
      config = BALANCE_SHEET_CONFIG,
      cache_path = temp_file
    )),
    NA
  )
  
  unlink(temp_file)
})
