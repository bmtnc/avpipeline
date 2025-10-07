test_that("filter_essential_financial_columns validates financial_statements parameter", {
  expect_error(
    filter_essential_financial_columns("not a df"),
    "^filter_essential_financial_columns\\(\\): \\[financial_statements\\] must be a data.frame, not character$"
  )
})

test_that("filter_essential_financial_columns filters to essential columns", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker            = c("A", "B"),
    fiscalDateEnding  = as.Date(c("2020-12-31", "2020-12-31")),
    reportedDate      = as.Date(c("2021-01-15", "2021-01-15")),
    reportedCurrency  = c("USD", "USD"),
    totalRevenue      = c(1000, 2000),
    netIncome         = c(150, 300),
    totalAssets       = c(5000, 8000),
    operatingCashflow = c(100, 200),
    extra_column1     = c("X", "Y"),
    extra_column2     = c(1, 2)
  )
  # nolint end

  result <- filter_essential_financial_columns(test_data)

  expect_s3_class(result, "data.frame")
  expect_true("ticker" %in% names(result))
  expect_true("fiscalDateEnding" %in% names(result))
  expect_true("totalRevenue" %in% names(result))
  expect_false("extra_column1" %in% names(result))
  expect_false("extra_column2" %in% names(result))
})
