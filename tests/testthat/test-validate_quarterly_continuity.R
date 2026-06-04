test_that("validate_quarterly_continuity validates financial_statements parameter", {
  expect_error(
    validate_quarterly_continuity("not a df"),
    "^Input data must be a data\\.frame\\. Received: character$"
  )
})

test_that("validate_quarterly_continuity validates required columns", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tribble(
    ~wrong_col,
    "A",
    "B"
  )
  # nolint end

  expect_error(
    validate_quarterly_continuity(test_data),
    "^Required columns missing from data: ticker, fiscalDateEnding\\. Available columns: wrong_col$"
  )
})

test_that("validate_quarterly_continuity processes data correctly", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~metric1,
    "A",     "2020-03-31",      100,
    "A",     "2020-06-30",      150,
    "A",     "2020-09-30",      200
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  # nolint end

  result <- validate_quarterly_continuity(test_data)

  expect_s3_class(result, "data.frame")
  expect_true("ticker" %in% names(result))
  expect_true("fiscalDateEnding" %in% names(result))
})
