test_that("load_single_financial_type validates cache_path is character scalar", {
  expect_error(
    load_single_financial_type(
      cache_path = 123,
      config = BALANCE_SHEET_CONFIG
    ),
    "^load_single_financial_type\\(\\): \\[cache_path\\] must be a character scalar, not numeric of length 1$"
  )
  
  expect_error(
    load_single_financial_type(
      cache_path = c("path1.csv", "path2.csv"),
      config = BALANCE_SHEET_CONFIG
    ),
    "^load_single_financial_type\\(\\): \\[cache_path\\] must be a character scalar, not character of length 2$"
  )
})

test_that("load_single_financial_type validates config is list", {
  expect_error(
    load_single_financial_type(
      cache_path = "cache/test.csv",
      config = "not a list"
    ),
    "^load_single_financial_type\\(\\): \\[config\\] must be a list, not character$"
  )
  
  expect_error(
    load_single_financial_type(
      cache_path = "cache/test.csv",
      config = 123
    ),
    "^load_single_financial_type\\(\\): \\[config\\] must be a list, not numeric$"
  )
})

test_that("load_single_financial_type loads data with correct structure", {
  temp_dir <- tempdir()
  temp_file <- file.path(temp_dir, "test_financial_data.parquet")
  
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker        = c("AAPL", "AAPL", "MSFT"),
    fiscal_date   = as.Date(c("2023-12-31", "2023-09-30", "2023-12-31")),
    total_assets  = c(352755000000, 353514000000, 411976000000)
  )
  # nolint end
  
  arrow::write_parquet(test_data, temp_file)
  
  test_config <- list(
    data_type_name = "Test Data",
    cache_date_columns = c("fiscal_date")
  )
  
  result <- suppressMessages(load_single_financial_type(temp_file, test_config))
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_true("ticker" %in% names(result))
  expect_true("fiscal_date" %in% names(result))
  
  unlink(temp_file)
})
