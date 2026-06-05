test_that("filter_essential_financial_columns validates financial_statements parameter", {
  expect_error(
    filter_essential_financial_columns("not a df"),
    "^Input data must be a data.frame. Received: character$"
  )
})

test_that("filter_essential_financial_columns filters to essential columns", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~reportedDate, ~reportedCurrency, ~totalRevenue, ~netIncome, ~totalAssets, ~operatingCashflow, ~extra_column1, ~extra_column2,
    "A",     "2020-12-31",      "2021-01-15",  "USD",             1000,          150,        5000,         100,                "X",            1,
    "B",     "2020-12-31",      "2021-01-15",  "USD",             2000,          300,        8000,         200,                "Y",            2
  ) %>%
    dplyr::mutate(dplyr::across(c(fiscalDateEnding, reportedDate), as.Date))
  # nolint end

  result <- filter_essential_financial_columns(test_data)

  expect_s3_class(result, "data.frame")
  expect_true("ticker" %in% names(result))
  expect_true("fiscalDateEnding" %in% names(result))
  expect_true("totalRevenue" %in% names(result))
  expect_false("extra_column1" %in% names(result))
  expect_false("extra_column2" %in% names(result))
})
