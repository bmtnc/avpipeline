test_that("align_statement_tickers validates statements parameter", {
  expect_error(
    align_statement_tickers("not a list"),
    "^align_statement_tickers\\(\\): \\[statements\\] must be a list, not character$"
  )
})

test_that("align_statement_tickers validates required names", {
  incomplete_list <- list(earnings = data.frame(ticker = "A"))

  expect_error(
    align_statement_tickers(incomplete_list),
    "^align_statement_tickers\\(\\): \\[statements\\] must contain: earnings, cash_flow, income_statement, balance_sheet$"
  )
})

test_that("align_statement_tickers filters to common tickers", {
  # nolint start
  # fmt: skip
  earnings_data <- tibble::tibble(
    ticker           = c("A", "B", "C"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2020-12-31", "2020-12-31"))
  )
  # nolint end

  # nolint start
  # fmt: skip
  cash_flow_data <- tibble::tibble(
    ticker           = c("A", "B"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2020-12-31"))
  )
  # nolint end

  # nolint start
  # fmt: skip
  income_statement_data <- tibble::tibble(
    ticker           = c("A", "B"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2020-12-31"))
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
    earnings = earnings_data,
    cash_flow = cash_flow_data,
    income_statement = income_statement_data,
    balance_sheet = balance_sheet_data
  )

  result <- align_statement_tickers(statements)

  expect_type(result, "list")
  expect_named(result, c("earnings", "cash_flow", "income_statement", "balance_sheet"))
  expect_equal(nrow(result$earnings), 2)
  expect_equal(nrow(result$cash_flow), 2)
  expect_equal(unique(result$earnings$ticker), c("A", "B"))
})
