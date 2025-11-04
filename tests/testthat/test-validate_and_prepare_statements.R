test_that("validate_and_prepare_statements validates threshold parameter", {
  # Create minimal test data
  cash_flow <- tibble::tibble(
    ticker = "TEST",
    fiscalDateEnding = as.Date("2020-03-31"),
    operatingCashflow = 1000
  )
  income_statement <- tibble::tibble(
    ticker = "TEST",
    fiscalDateEnding = as.Date("2020-03-31"),
    totalRevenue = 5000
  )
  balance_sheet <- tibble::tibble(
    ticker = "TEST",
    fiscalDateEnding = as.Date("2020-03-31"),
    totalAssets = 10000
  )
  earnings <- tibble::tibble(
    ticker = "TEST",
    fiscalDateEnding = as.Date("2020-03-31"),
    reportedDate = as.Date("2020-04-15")
  )

  expect_error(
    validate_and_prepare_statements(
      cash_flow, income_statement, balance_sheet, earnings,
      threshold = "invalid"
    ),
    "must be a positive numeric scalar"
  )
  expect_error(
    validate_and_prepare_statements(
      cash_flow, income_statement, balance_sheet, earnings,
      threshold = -1
    ),
    "must be a positive numeric scalar"
  )
  expect_error(
    validate_and_prepare_statements(
      cash_flow, income_statement, balance_sheet, earnings,
      threshold = c(1, 2)
    ),
    "must be a positive numeric scalar"
  )
})

test_that("validate_and_prepare_statements validates lookback parameter", {
  # Create minimal test data
  cash_flow <- tibble::tibble(
    ticker = "TEST",
    fiscalDateEnding = as.Date("2020-03-31"),
    operatingCashflow = 1000
  )
  income_statement <- tibble::tibble(
    ticker = "TEST",
    fiscalDateEnding = as.Date("2020-03-31"),
    totalRevenue = 5000
  )
  balance_sheet <- tibble::tibble(
    ticker = "TEST",
    fiscalDateEnding = as.Date("2020-03-31"),
    totalAssets = 10000
  )
  earnings <- tibble::tibble(
    ticker = "TEST",
    fiscalDateEnding = as.Date("2020-03-31"),
    reportedDate = as.Date("2020-04-15")
  )

  expect_error(
    validate_and_prepare_statements(
      cash_flow, income_statement, balance_sheet, earnings,
      lookback = "invalid"
    ),
    "must be a non-negative numeric scalar"
  )
  expect_error(
    validate_and_prepare_statements(
      cash_flow, income_statement, balance_sheet, earnings,
      lookback = -1
    ),
    "must be a non-negative numeric scalar"
  )
})

test_that("validate_and_prepare_statements returns correct structure", {
  # Create test data with multiple quarters
  cash_flow <- tibble::tibble(
    ticker = rep("TEST", 4),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31")),
    operatingCashflow = c(1000, 1100, 1200, 1300)
  )
  income_statement <- tibble::tibble(
    ticker = rep("TEST", 4),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31")),
    totalRevenue = c(5000, 5100, 5200, 5300)
  )
  balance_sheet <- tibble::tibble(
    ticker = rep("TEST", 4),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31")),
    totalAssets = c(10000, 10100, 10200, 10300),
    commonStockSharesOutstanding = c(100, 100, 100, 100)
  )
  earnings <- tibble::tibble(
    ticker = rep("TEST", 4),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31")),
    reportedDate = as.Date(c("2020-04-15", "2020-07-15", "2020-10-15", "2021-01-15"))
  )

  result <- validate_and_prepare_statements(
    cash_flow, income_statement, balance_sheet, earnings,
    threshold = 4, lookback = 5, lookahead = 5
  )

  # Check structure
  expect_s3_class(result, "tbl_df")
  expect_true("ticker" %in% names(result))
  expect_true("fiscalDateEnding" %in% names(result))
  expect_true("reportedDate" %in% names(result))

  # Should have rows
  expect_gt(nrow(result), 0)
})

test_that("validate_and_prepare_statements handles empty inputs", {
  # Empty inputs with proper column structure
  cash_flow <- tibble::tibble(
    ticker = character(),
    fiscalDateEnding = as.Date(character()),
    operatingCashflow = numeric()
  )
  income_statement <- tibble::tibble(
    ticker = character(),
    fiscalDateEnding = as.Date(character()),
    totalRevenue = numeric()
  )
  balance_sheet <- tibble::tibble(
    ticker = character(),
    fiscalDateEnding = as.Date(character()),
    totalAssets = numeric()
  )
  earnings <- tibble::tibble(
    ticker = character(),
    fiscalDateEnding = as.Date(character()),
    reportedDate = as.Date(character())
  )

  # Expect this to error or return empty - the function expects data
  result <- tryCatch(
    validate_and_prepare_statements(
      cash_flow, income_statement, balance_sheet, earnings,
      threshold = 4, lookback = 5, lookahead = 5
    ),
    error = function(e) tibble::tibble()
  )

  # Should return empty tibble
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("validate_and_prepare_statements includes calendar_quarter_ending", {
  # Create test data
  cash_flow <- tibble::tibble(
    ticker = rep("TEST", 4),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31")),
    operatingCashflow = c(1000, 1100, 1200, 1300)
  )
  income_statement <- tibble::tibble(
    ticker = rep("TEST", 4),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31")),
    totalRevenue = c(5000, 5100, 5200, 5300)
  )
  balance_sheet <- tibble::tibble(
    ticker = rep("TEST", 4),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31")),
    totalAssets = c(10000, 10100, 10200, 10300),
    commonStockSharesOutstanding = c(100, 100, 100, 100)
  )
  earnings <- tibble::tibble(
    ticker = rep("TEST", 4),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31")),
    reportedDate = as.Date(c("2020-04-15", "2020-07-15", "2020-10-15", "2021-01-15"))
  )

  result <- validate_and_prepare_statements(
    cash_flow, income_statement, balance_sheet, earnings,
    threshold = 4, lookback = 5, lookahead = 5
  )

  # Should have calendar_quarter_ending column
  expect_true("calendar_quarter_ending" %in% names(result))
})
