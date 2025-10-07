test_that("remove_all_na_financial_observations removes all-NA rows correctly", {
  # nolint start
  # fmt: skip
  cash_flow_test <- tibble::tibble(
    ticker               = c("A", "A", "B"),
    fiscalDateEnding     = as.Date(c("2020-12-31", "2021-12-31", "2020-12-31")),
    as_of_date           = as.Date(c("2021-01-15", "2022-01-15", "2021-01-15")),
    reportedCurrency     = c("USD", "USD", "USD"),
    operatingCashflow    = c(100, NA, 200),
    capitalExpenditures  = c(50, NA, 75)
  )
  # nolint end

  # nolint start
  # fmt: skip
  income_statement_test <- tibble::tibble(
    ticker               = c("A", "A", "B"),
    fiscalDateEnding     = as.Date(c("2020-12-31", "2021-12-31", "2020-12-31")),
    as_of_date           = as.Date(c("2021-01-15", "2022-01-15", "2021-01-15")),
    reportedCurrency     = c("USD", "USD", "USD"),
    totalRevenue         = c(1000, NA, 2000),
    netIncome            = c(150, NA, 300)
  )
  # nolint end

  # nolint start
  # fmt: skip
  balance_sheet_test <- tibble::tibble(
    ticker               = c("A", "A", "B"),
    fiscalDateEnding     = as.Date(c("2020-12-31", "2021-12-31", "2020-12-31")),
    as_of_date           = as.Date(c("2021-01-15", "2022-01-15", "2021-01-15")),
    reportedCurrency     = c("USD", "USD", "USD"),
    totalAssets          = c(5000, NA, 8000),
    totalLiabilities     = c(3000, NA, 5000)
  )
  # nolint end

  statements <- list(
    cash_flow = cash_flow_test,
    income_statement = income_statement_test,
    balance_sheet = balance_sheet_test
  )

  result <- remove_all_na_financial_observations(statements)

  expect_type(result, "list")
  expect_named(result, c("cash_flow", "income_statement", "balance_sheet"))
  expect_equal(nrow(result$cash_flow), 2)
  expect_equal(nrow(result$income_statement), 2)
  expect_equal(nrow(result$balance_sheet), 2)
})

test_that("remove_all_na_financial_observations validates input type", {
  expect_error(
    remove_all_na_financial_observations("not a list"),
    "^remove_all_na_financial_observations\\(\\): \\[statements\\] must be a list, not character$"
  )
})

test_that("remove_all_na_financial_observations validates required names", {
  incomplete_list <- list(cash_flow = data.frame(x = 1))

  expect_error(
    remove_all_na_financial_observations(incomplete_list),
    "^remove_all_na_financial_observations\\(\\): \\[statements\\] must contain: cash_flow, income_statement, balance_sheet$"
  )
})
