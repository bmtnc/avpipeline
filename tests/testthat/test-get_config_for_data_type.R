test_that("get_config_for_data_type returns correct config for price", {
  config <- get_config_for_data_type("price")
  expect_equal(config$api_function, "TIME_SERIES_DAILY_ADJUSTED")
  expect_equal(config$parser_func, "parse_price_response")
})

test_that("get_config_for_data_type returns correct config for splits", {
  config <- get_config_for_data_type("splits")
  expect_equal(config$api_function, "SPLITS")
  expect_equal(config$parser_func, "parse_splits_response")
})

test_that("get_config_for_data_type returns correct config for balance_sheet", {
  config <- get_config_for_data_type("balance_sheet")
  expect_equal(config$api_function, "BALANCE_SHEET")
  expect_equal(config$parser_func, "parse_balance_sheet_response")
})

test_that("get_config_for_data_type returns correct config for income_statement", {
  config <- get_config_for_data_type("income_statement")
  expect_equal(config$api_function, "INCOME_STATEMENT")
  expect_equal(config$parser_func, "parse_income_statement_response")
})

test_that("get_config_for_data_type returns correct config for cash_flow", {
  config <- get_config_for_data_type("cash_flow")
  expect_equal(config$api_function, "CASH_FLOW")
  expect_equal(config$parser_func, "parse_cash_flow_response")
})

test_that("get_config_for_data_type returns correct config for earnings", {
  config <- get_config_for_data_type("earnings")
  expect_equal(config$api_function, "EARNINGS")
  expect_equal(config$parser_func, "parse_earnings_response")
})

test_that("get_config_for_data_type returns NULL for unknown data_type", {
  config <- get_config_for_data_type("unknown_type")
  expect_null(config)
})

test_that("get_config_for_data_type validates data_type parameter", {
  expect_error(get_config_for_data_type(123), "character scalar")
  expect_error(get_config_for_data_type(c("price", "splits")), "character scalar")
})
