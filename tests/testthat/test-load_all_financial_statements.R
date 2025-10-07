test_that("load_all_financial_statements validates cache_paths is list", {
  expect_error(
    load_all_financial_statements(cache_paths = "not a list"),
    "^load_all_financial_statements\\(\\): \\[cache_paths\\] must be a list, not character$"
  )
  
  expect_error(
    load_all_financial_statements(cache_paths = 123),
    "^load_all_financial_statements\\(\\): \\[cache_paths\\] must be a list, not numeric$"
  )
})

test_that("load_all_financial_statements validates required keys present", {
  incomplete_paths <- list(
    balance_sheet = "cache/bs.csv",
    cash_flow = "cache/cf.csv"
  )
  
  expect_error(
    load_all_financial_statements(cache_paths = incomplete_paths),
    "^load_all_financial_statements\\(\\): \\[cache_paths\\] must contain keys: balance_sheet, cash_flow, income_statement, earnings$"
  )
})

test_that("load_all_financial_statements loads all data types", {
  temp_dir <- tempdir()
  
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker      = c("AAPL", "MSFT"),
    fiscal_date = as.Date(c("2023-12-31", "2023-12-31")),
    value       = c(100, 200)
  )
  # nolint end
  
  bs_file <- file.path(temp_dir, "bs.csv")
  cf_file <- file.path(temp_dir, "cf.csv")
  is_file <- file.path(temp_dir, "is.csv")
  earnings_file <- file.path(temp_dir, "earnings.csv")
  
  readr::write_csv(test_data, bs_file)
  readr::write_csv(test_data, cf_file)
  readr::write_csv(test_data, is_file)
  readr::write_csv(test_data, earnings_file)
  
  cache_paths <- list(
    balance_sheet = bs_file,
    cash_flow = cf_file,
    income_statement = is_file,
    earnings = earnings_file
  )
  
  result <- suppressMessages(load_all_financial_statements(cache_paths))
  
  expect_type(result, "list")
  expect_named(result, c("balance_sheet", "cash_flow", "income_statement", "earnings"))
  expect_s3_class(result$balance_sheet, "data.frame")
  expect_s3_class(result$cash_flow, "data.frame")
  expect_s3_class(result$income_statement, "data.frame")
  expect_s3_class(result$earnings, "data.frame")
  
  unlink(c(bs_file, cf_file, is_file, earnings_file))
})
