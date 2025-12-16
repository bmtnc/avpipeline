test_that("generate_raw_data_s3_key generates correct key", {
  expect_equal(
    generate_raw_data_s3_key("AAPL", "balance_sheet"),
    "raw/AAPL/balance_sheet.parquet"
  )

  expect_equal(
    generate_raw_data_s3_key("MSFT", "price"),
    "raw/MSFT/price.parquet"
  )
})

test_that("generate_raw_data_s3_key validates inputs", {
  expect_error(generate_raw_data_s3_key(123, "price"), "ticker")
  expect_error(generate_raw_data_s3_key("", "price"), "ticker")
  expect_error(generate_raw_data_s3_key(c("A", "B"), "price"), "ticker")
  expect_error(generate_raw_data_s3_key("AAPL", 123), "data_type")
  expect_error(generate_raw_data_s3_key("AAPL", ""), "data_type")
})

test_that("generate_version_snapshot_s3_key generates correct key", {
  test_date <- as.Date("2024-12-15")

  expect_equal(
    generate_version_snapshot_s3_key("AAPL", "balance_sheet", test_date),
    "raw/AAPL/_versions/balance_sheet_2024-12-15.parquet"
  )

  expect_equal(
    generate_version_snapshot_s3_key("MSFT", "income_statement", test_date),
    "raw/MSFT/_versions/income_statement_2024-12-15.parquet"
  )
})

test_that("generate_version_snapshot_s3_key validates inputs", {
  test_date <- as.Date("2024-12-15")

  expect_error(generate_version_snapshot_s3_key(123, "price", test_date), "ticker")
  expect_error(generate_version_snapshot_s3_key("", "price", test_date), "ticker")
  expect_error(generate_version_snapshot_s3_key("AAPL", "", test_date), "data_type")
  expect_error(generate_version_snapshot_s3_key("AAPL", "price", "2024-12-15"), "snapshot_date")
})
