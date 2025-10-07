test_that("standardize_to_calendar_quarters validates financial_statements parameter", {
  expect_error(
    standardize_to_calendar_quarters("not a df"),
    "^standardize_to_calendar_quarters\\(\\): \\[financial_statements\\] must be a data.frame, not character$"
  )
})

test_that("standardize_to_calendar_quarters validates fiscalDateEnding column", {
  test_data <- tibble::tibble(wrong_col = c("A", "B"))

  expect_error(
    standardize_to_calendar_quarters(test_data),
    "^standardize_to_calendar_quarters\\(\\): \\[financial_statements\\] must contain fiscalDateEnding column$"
  )
})

test_that("standardize_to_calendar_quarters maps fiscal dates correctly", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker           = c("A", "A", "A", "A"),
    fiscalDateEnding = as.Date(c("2020-01-31", "2020-03-31", "2020-06-30", "2020-12-31"))
  )
  # nolint end

  result <- standardize_to_calendar_quarters(test_data)

  expect_true("calendar_quarter_ending" %in% names(result))
  expect_equal(result$calendar_quarter_ending[1], as.Date("2019-12-31"))
  expect_equal(result$calendar_quarter_ending[2], as.Date("2020-03-31"))
  expect_equal(result$calendar_quarter_ending[3], as.Date("2020-06-30"))
  expect_equal(result$calendar_quarter_ending[4], as.Date("2020-12-31"))
})
