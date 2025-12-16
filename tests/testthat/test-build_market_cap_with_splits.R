test_that("build_market_cap_with_splits validates start_date parameter", {
  # Create minimal test data
  price_data <- tibble::tibble(
    ticker = "TEST",
    date = as.Date("2020-01-01"),
    close = 100
  )
  # Empty splits_data with proper column structure
  splits_data <- tibble::tibble(
    ticker = character(),
    effective_date = as.Date(character()),
    split_factor = numeric(),
    as_of_date = as.Date(character())
  )
  financial_statements <- tibble::tibble(
    ticker = "TEST",
    fiscalDateEnding = as.Date("2020-01-01"),
    reportedDate = as.Date("2020-01-15"),
    commonStockSharesOutstanding = 1000000
  )

  expect_error(
    build_market_cap_with_splits(
      price_data, splits_data, financial_statements,
      start_date = "2020-01-01"
    ),
    "^start_date must be a Date object\\. Received: character$"
  )
  expect_error(
    build_market_cap_with_splits(
      price_data, splits_data, financial_statements,
      start_date = c(as.Date("2020-01-01"), as.Date("2020-01-02"))
    ),
    "^start_date must be a Date scalar \\(length 1\\)\\. Received length: 2$"
  )
})

test_that("build_market_cap_with_splits returns correct structure", {
  # Create test data
  price_data <- tibble::tibble(
    ticker = "TEST",
    date = as.Date(c("2020-01-01", "2020-01-02", "2020-01-03")),
    close = c(100, 101, 102)
  )
  # Empty splits_data with proper column structure
  splits_data <- tibble::tibble(
    ticker = character(),
    effective_date = as.Date(character()),
    split_factor = numeric(),
    as_of_date = as.Date(character())
  )
  financial_statements <- tibble::tibble(
    ticker = "TEST",
    fiscalDateEnding = as.Date("2020-01-01"),
    reportedDate = as.Date("2020-01-01"),
    commonStockSharesOutstanding = 1000000
  )

  result <- build_market_cap_with_splits(
    price_data, splits_data, financial_statements,
    start_date = as.Date("2020-01-01")
  )

  # Check structure
  expect_s3_class(result, "tbl_df")
  expect_named(result, c(
    "ticker", "date", "post_filing_split_multiplier",
    "effective_shares_outstanding", "market_cap"
  ))

  # Should have 3 rows (one per price date)
  expect_equal(nrow(result), 3)
  expect_true(all(result$ticker == "TEST"))
})

test_that("build_market_cap_with_splits calculates market cap correctly without splits", {
  # Create simple test case without splits
  price_data <- tibble::tibble(
    ticker = "TEST",
    date = as.Date(c("2020-01-02", "2020-01-03")),
    close = c(10, 20)
  )
  # Empty splits_data with proper column structure
  splits_data <- tibble::tibble(
    ticker = character(),
    effective_date = as.Date(character()),
    split_factor = numeric(),
    as_of_date = as.Date(character())
  )
  financial_statements <- tibble::tibble(
    ticker = "TEST",
    fiscalDateEnding = as.Date("2020-01-01"),
    reportedDate = as.Date("2020-01-01"),
    commonStockSharesOutstanding = 100
  )

  result <- build_market_cap_with_splits(
    price_data, splits_data, financial_statements,
    start_date = as.Date("2020-01-01")
  )

  # Market cap should be price * shares / 1M
  # Day 1: 10 * 100 / 1M = 0.001
  # Day 2: 20 * 100 / 1M = 0.002
  expect_equal(result$market_cap[1], 10 * 100 / 1e6)
  expect_equal(result$market_cap[2], 20 * 100 / 1e6)
  expect_equal(result$effective_shares_outstanding[1], 100)
  expect_equal(result$effective_shares_outstanding[2], 100)
})

test_that("build_market_cap_with_splits handles empty inputs", {
  # Empty price data with proper column structure
  price_data <- tibble::tibble(
    ticker = character(),
    date = as.Date(character()),
    close = numeric()
  )
  # Empty splits_data with proper column structure
  splits_data <- tibble::tibble(
    ticker = character(),
    effective_date = as.Date(character()),
    split_factor = numeric(),
    as_of_date = as.Date(character())
  )
  financial_statements <- tibble::tibble(
    ticker = character(),
    fiscalDateEnding = as.Date(character()),
    reportedDate = as.Date(character()),
    commonStockSharesOutstanding = numeric()
  )

  result <- build_market_cap_with_splits(
    price_data, splits_data, financial_statements,
    start_date = as.Date("2020-01-01")
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("build_market_cap_with_splits filters by start_date", {
  price_data <- tibble::tibble(
    ticker = "TEST",
    date = as.Date(c("2019-12-31", "2020-01-01", "2020-01-02")),
    close = c(100, 101, 102)
  )
  # Empty splits_data with proper column structure
  splits_data <- tibble::tibble(
    ticker = character(),
    effective_date = as.Date(character()),
    split_factor = numeric(),
    as_of_date = as.Date(character())
  )
  financial_statements <- tibble::tibble(
    ticker = "TEST",
    fiscalDateEnding = as.Date(c("2019-12-31", "2020-01-01")),
    reportedDate = as.Date(c("2019-12-31", "2020-01-01")),
    commonStockSharesOutstanding = c(1000000, 1000000)
  )

  result <- build_market_cap_with_splits(
    price_data, splits_data, financial_statements,
    start_date = as.Date("2020-01-01")
  )

  # Should only include dates >= start_date
  expect_true(all(result$date >= as.Date("2020-01-01")))
  expect_equal(nrow(result), 2)  # Only 2020-01-01 and 2020-01-02
})
