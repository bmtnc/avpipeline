test_that("join_daily_and_financial_data joins data correctly", {
  # nolint start
  # fmt: skip
  price_data <- tibble::tibble(
    ticker      = c("AAPL",  "AAPL"),
    date        = as.Date(c("2023-01-01", "2023-01-02")),
    open        = c(150.0,   151.0),
    close       = c(152.0,   153.0),
    as_of_date  = as.Date(c("2023-01-01", "2023-01-02"))
  )
  
  market_cap_data <- tibble::tibble(
    ticker                          = c("AAPL",  "AAPL"),
    date                            = as.Date(c("2023-01-01", "2023-01-02")),
    market_cap                      = c(2500000, 2510000),
    effective_shares_outstanding    = c(16000,   16100),
    as_of_date                      = as.Date(c("2023-01-01", "2023-01-02")),
    close                           = c(152.0,   153.0),
    commonStockSharesOutstanding    = c(16000,   16100),
    has_financial_data              = c(TRUE,    TRUE),
    days_since_financial_report     = c(10,      11),
    reportedDate                    = as.Date(c("2022-12-20", "2022-12-20"))
  )
  
  ttm_data <- tibble::tibble(
    ticker                           = c("AAPL",  "AAPL"),
    date                             = as.Date(c("2023-01-01", "2023-01-02")),
    totalRevenue_ttm                 = c(400000,  400000),
    calendar_quarter_ending          = as.Date(c("2022-12-31", "2022-12-31")),
    fiscalDateEnding                 = as.Date(c("2022-12-31", "2022-12-31")),
    reportedDate                     = as.Date(c("2022-12-20", "2022-12-20"))
  )
  # nolint end
  
  result <- join_daily_and_financial_data(price_data, market_cap_data, ttm_data)
  
  # Check that result has expected number of rows
  expect_equal(nrow(result), 2)
  
  # Check that key columns exist
  expect_true("ticker" %in% names(result))
  expect_true("date" %in% names(result))
  expect_true("open" %in% names(result))
  expect_true("market_cap" %in% names(result))
  expect_true("totalRevenue_ttm" %in% names(result))
  
  # Check that as_of_date was removed from price data
  expect_false("as_of_date" %in% names(result))
  
  # Check that close from price_data is preserved
  expect_true("close" %in% names(result))
  
  # Check that unnecessary market cap columns were removed
  expect_false("has_financial_data" %in% names(result))
  expect_false("days_since_financial_report" %in% names(result))
  expect_false("commonStockSharesOutstanding" %in% names(result))
})

test_that("join_daily_and_financial_data orders columns correctly", {
  # nolint start
  # fmt: skip
  price_data <- tibble::tibble(
    ticker = c("AAPL"),
    date   = as.Date("2023-01-01"),
    open   = c(150.0)
  )
  
  market_cap_data <- tibble::tibble(
    ticker     = c("AAPL"),
    date       = as.Date("2023-01-01"),
    market_cap = c(2500000)
  )
  
  ttm_data <- tibble::tibble(
    ticker                  = c("AAPL"),
    date                    = as.Date("2023-01-01"),
    totalRevenue_ttm        = c(400000),
    calendar_quarter_ending = as.Date("2022-12-31"),
    fiscalDateEnding        = as.Date("2022-12-31")
  )
  # nolint end
  
  result <- join_daily_and_financial_data(price_data, market_cap_data, ttm_data)
  
  # Check that ticker and date are first two columns
  expect_equal(names(result)[1], "ticker")
  expect_equal(names(result)[2], "date")
  
  # Check that date-containing columns come before calendar_quarter_ending
  date_col_positions <- which(names(result) %in% c("fiscalDateEnding", "calendar_quarter_ending"))
  expect_true(all(date_col_positions > 2))
})

test_that("join_daily_and_financial_data validates input types", {
  valid_data <- tibble::tibble(
    ticker = c("AAPL"),
    date = as.Date("2023-01-01")
  )

  expect_error(
    join_daily_and_financial_data("not_a_dataframe", valid_data, valid_data),
    "^Input data must be a data\\.frame\\. Received: character$"
  )

  expect_error(
    join_daily_and_financial_data(valid_data, "not_a_dataframe", valid_data),
    "^Input data must be a data\\.frame\\. Received: character$"
  )

  expect_error(
    join_daily_and_financial_data(valid_data, valid_data, "not_a_dataframe"),
    "^Input data must be a data\\.frame\\. Received: character$"
  )
})

test_that("join_daily_and_financial_data validates required columns", {
  # Missing ticker column
  invalid_price <- tibble::tibble(
    date = as.Date("2023-01-01"),
    open = c(150.0)
  )

  valid_data <- tibble::tibble(
    ticker = c("AAPL"),
    date = as.Date("2023-01-01")
  )

  expect_error(
    join_daily_and_financial_data(invalid_price, valid_data, valid_data),
    "^Required columns missing from data: ticker\\. Available columns: date, open$"
  )

  # Missing date column from market_cap_data
  invalid_market <- tibble::tibble(
    ticker = c("AAPL"),
    market_cap = c(2500000)
  )

  expect_error(
    join_daily_and_financial_data(valid_data, invalid_market, valid_data),
    "^Required columns missing from data: date\\. Available columns: ticker, market_cap$"
  )

  # Missing ticker column from ttm_data
  invalid_ttm <- tibble::tibble(
    date = as.Date("2023-01-01"),
    totalRevenue_ttm = c(400000)
  )

  expect_error(
    join_daily_and_financial_data(valid_data, valid_data, invalid_ttm),
    "^Required columns missing from data: ticker\\. Available columns: date, totalRevenue_ttm$"
  )
})

test_that("join_daily_and_financial_data handles missing matches with left join", {
  # nolint start
  # fmt: skip
  price_data <- tibble::tibble(
    ticker = c("AAPL",  "AAPL",  "MSFT"),
    date   = as.Date(c("2023-01-01", "2023-01-02", "2023-01-01")),
    open   = c(150.0,   151.0,   250.0)
  )
  
  market_cap_data <- tibble::tibble(
    ticker     = c("AAPL",  "AAPL"),
    date       = as.Date(c("2023-01-01", "2023-01-02")),
    market_cap = c(2500000, 2510000)
  )
  
  ttm_data <- tibble::tibble(
    ticker           = c("AAPL"),
    date             = as.Date("2023-01-01"),
    totalRevenue_ttm = c(400000)
  )
  # nolint end
  
  result <- join_daily_and_financial_data(price_data, market_cap_data, ttm_data)
  
  # All price data rows should be preserved (left join)
  expect_equal(nrow(result), 3)
  
  # MSFT row should have NA for market_cap and totalRevenue_ttm
  msft_row <- result[result$ticker == "MSFT", ]
  expect_true(is.na(msft_row$market_cap))
  expect_true(is.na(msft_row$totalRevenue_ttm))
})

test_that("join_daily_and_financial_data handles empty data frames", {
  # nolint start
  # fmt: skip
  empty_price <- tibble::tibble(
    ticker = character(0),
    date   = as.Date(character(0)),
    open   = numeric(0)
  )
  
  empty_market <- tibble::tibble(
    ticker     = character(0),
    date       = as.Date(character(0)),
    market_cap = numeric(0)
  )
  
  empty_ttm <- tibble::tibble(
    ticker           = character(0),
    date             = as.Date(character(0)),
    totalRevenue_ttm = numeric(0)
  )
  # nolint end
  
  result <- join_daily_and_financial_data(empty_price, empty_market, empty_ttm)
  
  # Result should be empty but have proper structure
  expect_equal(nrow(result), 0)
  expect_true("ticker" %in% names(result))
  expect_true("date" %in% names(result))
})
