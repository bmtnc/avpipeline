test_that("clean_all_statement_anomalies validates statements parameter", {
  expect_error(
    clean_all_statement_anomalies("not a list"),
    "^clean_all_statement_anomalies\\(\\): \\[statements\\] must be a list, not character$"
  )
})

test_that("clean_all_statement_anomalies validates required names", {
  incomplete_list <- list(cash_flow = data.frame(x = 1))

  expect_error(
    clean_all_statement_anomalies(incomplete_list),
    "^clean_all_statement_anomalies\\(\\): \\[statements\\] must contain: cash_flow, income_statement, balance_sheet$"
  )
})

test_that("clean_all_statement_anomalies validates threshold parameter", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~metric1,
    "A",     "2020-12-31",      100,
    "A",     "2021-12-31",      150
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  # nolint end

  statements <- list(
    cash_flow = test_data,
    income_statement = test_data,
    balance_sheet = test_data
  )

  expect_error(
    clean_all_statement_anomalies(statements, threshold = -1),
    "^threshold must be greater than 0\\. Received: -1$"
  )
})

test_that("clean_all_statement_anomalies processes all statements", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~reportedCurrency, ~as_of_date,  ~metric1,
    "A",     "2020-12-31",      "USD",             "2021-01-15", 100,
    "A",     "2021-12-31",      "USD",             "2022-01-15", 150
  ) %>%
    dplyr::mutate(dplyr::across(c(fiscalDateEnding, as_of_date), as.Date))
  # nolint end

  statements <- list(
    cash_flow = test_data,
    income_statement = test_data,
    balance_sheet = test_data
  )

  result <- clean_all_statement_anomalies(statements, min_obs = 1)

  expect_type(result, "list")
  expect_named(result, c("income_statement", "cash_flow", "balance_sheet"))
  expect_s3_class(result$cash_flow, "data.frame")
  expect_s3_class(result$income_statement, "data.frame")
  expect_s3_class(result$balance_sheet, "data.frame")
})
