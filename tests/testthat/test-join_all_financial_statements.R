test_that("join_all_financial_statements validates statements parameter", {
  expect_error(
    join_all_financial_statements("not a list", data.frame(ticker = "A", fiscalDateEnding = as.Date("2020-12-31"))),
    "^join_all_financial_statements\\(\\): \\[statements\\] must be a list, not character$"
  )
})

test_that("join_all_financial_statements validates valid_dates parameter", {
  statements <- list(
    earnings = data.frame(ticker = "A"),
    cash_flow = data.frame(ticker = "A"),
    income_statement = data.frame(ticker = "A"),
    balance_sheet = data.frame(ticker = "A")
  )

  expect_error(
    join_all_financial_statements(statements, "not a df"),
    "^join_all_financial_statements\\(\\): \\[valid_dates\\] must be a data.frame, not character$"
  )
})

test_that("join_all_financial_statements validates required columns", {
  statements <- list(
    earnings = data.frame(ticker = "A"),
    cash_flow = data.frame(ticker = "A"),
    income_statement = data.frame(ticker = "A"),
    balance_sheet = data.frame(ticker = "A")
  )

  expect_error(
    join_all_financial_statements(statements, data.frame(wrong_col = "A")),
    "^join_all_financial_statements\\(\\): \\[valid_dates\\] must contain columns: ticker, fiscalDateEnding$"
  )
})

test_that("join_all_financial_statements joins statements correctly", {
  # nolint start
  # fmt: skip
  valid_dates <- tibble::tibble(
    ticker           = c("A", "B"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2020-12-31"))
  )
  # nolint end

  # nolint start
  # fmt: skip
  earnings_data <- tibble::tibble(
    ticker           = c("A", "B"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2020-12-31")),
    reportedDate     = as.Date(c("2021-01-15", "2021-01-15"))
  )
  # nolint end

  # nolint start
  # fmt: skip
  cash_flow_data <- tibble::tibble(
    ticker                = c("A", "B"),
    fiscalDateEnding      = as.Date(c("2020-12-31", "2020-12-31")),
    operatingCashflow     = c(100, 200)
  )
  # nolint end

  # nolint start
  # fmt: skip
  income_statement_data <- tibble::tibble(
    ticker           = c("A", "B"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2020-12-31")),
    totalRevenue     = c(1000, 2000)
  )
  # nolint end

  # nolint start
  # fmt: skip
  balance_sheet_data <- tibble::tibble(
    ticker           = c("A", "B"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2020-12-31")),
    totalAssets      = c(5000, 8000)
  )
  # nolint end

  statements <- list(
    earnings = earnings_data,
    cash_flow = cash_flow_data,
    income_statement = income_statement_data,
    balance_sheet = balance_sheet_data
  )

  result <- join_all_financial_statements(statements, valid_dates)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_true("ticker" %in% names(result))
  expect_true("fiscalDateEnding" %in% names(result))
  expect_true("totalRevenue" %in% names(result))
  expect_true("totalAssets" %in% names(result))
  expect_true("operatingCashflow" %in% names(result))
})
