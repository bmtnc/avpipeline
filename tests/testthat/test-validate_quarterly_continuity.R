test_that("validate_quarterly_continuity validates financial_statements parameter", {
  expect_error(
    validate_quarterly_continuity("not a df"),
    "^validate_quarterly_continuity\\(\\): \\[financial_statements\\] must be a data.frame, not character$"
  )
})

test_that("validate_quarterly_continuity validates required columns", {
  test_data <- tibble::tibble(wrong_col = c("A", "B"))

  expect_error(
    validate_quarterly_continuity(test_data),
    "^validate_quarterly_continuity\\(\\): \\[financial_statements\\] must contain columns: ticker, fiscalDateEnding$"
  )
})

test_that("validate_quarterly_continuity processes data correctly", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker           = c("A", "A", "A"),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30")),
    metric1          = c(100, 150, 200)
  )
  # nolint end

  result <- validate_quarterly_continuity(test_data)

  expect_s3_class(result, "data.frame")
  expect_true("ticker" %in% names(result))
  expect_true("fiscalDateEnding" %in% names(result))
})
