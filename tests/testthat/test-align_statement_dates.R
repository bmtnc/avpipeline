test_that("align_statement_dates validates statements parameter", {
  expect_error(
    align_statement_dates("not a list"),
    "^align_statement_dates\\(\\): \\[statements\\] must be a list, not character$"
  )
})

test_that("align_statement_dates validates required names", {
  incomplete_list <- list(cash_flow = data.frame(ticker = "A"))

  expect_error(
    align_statement_dates(incomplete_list),
    "^align_statement_dates\\(\\): \\[statements\\] must contain: cash_flow, income_statement, balance_sheet$"
  )
})

test_that("align_statement_dates finds common ticker-date combinations", {
  # nolint start
  # fmt: skip
  cash_flow_data <- tibble::tibble(
    ticker           = c("A", "A", "B"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2021-12-31", "2020-12-31"))
  )
  # nolint end

  # nolint start
  # fmt: skip
  income_statement_data <- tibble::tibble(
    ticker           = c("A", "A", "B"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2021-12-31", "2020-12-31"))
  )
  # nolint end

  # nolint start
  # fmt: skip
  balance_sheet_data <- tibble::tibble(
    ticker           = c("A", "B"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2020-12-31"))
  )
  # nolint end

  statements <- list(
    cash_flow = cash_flow_data,
    income_statement = income_statement_data,
    balance_sheet = balance_sheet_data
  )

  result <- align_statement_dates(statements)

  expect_s3_class(result, "data.frame")
  expect_true("ticker" %in% names(result))
  expect_true("fiscalDateEnding" %in% names(result))
  expect_equal(nrow(result), 2)
})
