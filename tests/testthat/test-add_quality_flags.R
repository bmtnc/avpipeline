test_that("add_quality_flags validates financial_statements parameter", {
  expect_error(
    add_quality_flags("not a df"),
    "^Input data must be a data.frame. Received: character$"
  )
})

test_that("add_quality_flags adds quality flag columns", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~reportedDate, ~totalRevenue, ~netIncome, ~totalAssets, ~totalLiabilities, ~operatingCashflow,
    "A",     "2020-12-31",      "2021-01-15",  1000,          150,        5000,         3000,              100,
    "B",     "2020-12-31",      NA,            NA,            NA,         NA,           NA,                NA
  ) %>%
    dplyr::mutate(dplyr::across(c(fiscalDateEnding, reportedDate), as.Date))
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
