test_that("add_quality_flags validates financial_statements parameter", {
  expect_error(
    add_quality_flags("not a df"),
    "^Input data must be a data.frame. Received: character$"
  )
})

test_that("add_quality_flags adds quality flag columns", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker            = c("A", "B"),
    fiscalDateEnding  = as.Date(c("2020-12-31", "2020-12-31")),
    reportedDate      = as.Date(c("2021-01-15", NA)),
    totalRevenue      = c(1000, NA),
    netIncome         = c(150, NA),
    totalAssets       = c(5000, NA),
    totalLiabilities  = c(3000, NA),
    operatingCashflow = c(100, NA)
  )
  # nolint end

  result <- add_quality_flags(test_data)

  expect_true("has_income_statement" %in% names(result))
  expect_true("has_balance_sheet" %in% names(result))
  expect_true("has_cash_flow" %in% names(result))
  expect_true("has_complete_financials" %in% names(result))
  expect_true("has_earnings_metadata" %in% names(result))
  expect_equal(result$has_complete_financials[1], TRUE)
  expect_equal(result$has_complete_financials[2], FALSE)
  expect_equal(result$has_earnings_metadata[1], TRUE)
  expect_equal(result$has_earnings_metadata[2], FALSE)
})
