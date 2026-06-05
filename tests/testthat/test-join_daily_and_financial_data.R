test_that("join_daily_and_financial_data joins data correctly", {
  # nolint start
  # fmt: skip
  price_data <- tibble::tribble(
    ~ticker, ~date,        ~open, ~close, ~as_of_date,
    "AAPL",  "2023-01-01", 150.0, 152.0, "2023-01-01",
    "AAPL",  "2023-01-02", 151.0, 153.0, "2023-01-02"
  ) %>%
    dplyr::mutate(dplyr::across(c(date, as_of_date), as.Date))

  market_cap_data <- tibble::tribble(
    ~ticker, ~date,        ~market_cap, ~effective_shares_outstanding, ~as_of_date,  ~close, ~commonStockSharesOutstanding, ~has_financial_data, ~days_since_financial_report, ~reportedDate,
    "AAPL",  "2023-01-01", 2500000,     16000,                         "2023-01-01", 152.0,  16000,                         TRUE,                10,                           "2022-12-20",
    "AAPL",  "2023-01-02", 2510000,     16100,                         "2023-01-02", 153.0,  16100,                         TRUE,                11,                           "2022-12-20"
  ) %>%
    dplyr::mutate(dplyr::across(c(date, as_of_date, reportedDate), as.Date))

  ttm_data <- tibble::tribble(
    ~ticker, ~date,        ~totalRevenue_ttm, ~calendar_quarter_ending, ~fiscalDateEnding, ~reportedDate,
    "AAPL",  "2023-01-01", 400000,            "2022-12-31",             "2022-12-31",      "2022-12-20",
    "AAPL",  "2023-01-02", 400000,            "2022-12-31",             "2022-12-31",      "2022-12-20"
  ) %>%
    dplyr::mutate(dplyr::across(c(date, calendar_quarter_ending, fiscalDateEnding, reportedDate), as.Date))
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
  price_data <- tibble::tribble(
    ~ticker, ~date,        ~open,
    "AAPL",  "2023-01-01", 150.0
  ) %>%
    dplyr::mutate(date = as.Date(date))

  market_cap_data <- tibble::tribble(
    ~ticker, ~date,        ~market_cap,
    "AAPL",  "2023-01-01", 2500000
  ) %>%
    dplyr::mutate(date = as.Date(date))

  ttm_data <- tibble::tribble(
    ~ticker, ~date,        ~totalRevenue_ttm, ~calendar_quarter_ending, ~fiscalDateEnding,
    "AAPL",  "2023-01-01", 400000,            "2022-12-31",             "2022-12-31"
  ) %>%
    dplyr::mutate(dplyr::across(c(date, calendar_quarter_ending, fiscalDateEnding), as.Date))
  # nolint end

  result <- join_daily_and_financial_data(price_data, market_cap_data, ttm_data)

  # Check that ticker and date are first two columns
  expect_equal(names(result)[1], "ticker")
  expect_equal(names(result)[2], "date")

  # Check that date-containing columns come before calendar_quarter_ending
  date_col_positions <- which(
    names(result) %in% c("fiscalDateEnding", "calendar_quarter_ending")
  )
  expect_true(all(date_col_positions > 2))
})

test_that("join_daily_and_financial_data validates input types", {
  # nolint start
  # fmt: skip
  valid_data <- tibble::tribble(
    ~ticker, ~date,
    "AAPL",  "2023-01-01"
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

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
  # nolint start
  # fmt: skip
  invalid_price <- tibble::tribble(
    ~date,        ~open,
    "2023-01-01", 150.0
  ) %>%
    dplyr::mutate(date = as.Date(date))

  valid_data <- tibble::tribble(
    ~ticker, ~date,
    "AAPL",  "2023-01-01"
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  expect_error(
    join_daily_and_financial_data(invalid_price, valid_data, valid_data),
    "^Required columns missing from data: ticker\\. Available columns: date, open$"
  )

  # Missing date column from market_cap_data
  # nolint start
  # fmt: skip
  invalid_market <- tibble::tribble(
    ~ticker, ~market_cap,
    "AAPL",  2500000
  )
  # nolint end

  expect_error(
    join_daily_and_financial_data(valid_data, invalid_market, valid_data),
    "^Required columns missing from data: date\\. Available columns: ticker, market_cap$"
  )

  # Missing ticker column from ttm_data
  # nolint start
  # fmt: skip
  invalid_ttm <- tibble::tribble(
    ~date,        ~totalRevenue_ttm,
    "2023-01-01", 400000
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  expect_error(
    join_daily_and_financial_data(valid_data, valid_data, invalid_ttm),
    "^Required columns missing from data: ticker\\. Available columns: date, totalRevenue_ttm$"
  )
})

test_that("join_daily_and_financial_data handles missing matches with left join", {
  # nolint start
  # fmt: skip
  price_data <- tibble::tribble(
    ~ticker, ~date,        ~open,
    "AAPL",  "2023-01-01", 150.0,
    "AAPL",  "2023-01-02", 151.0,
    "MSFT",  "2023-01-01", 250.0
  ) %>%
    dplyr::mutate(date = as.Date(date))

  market_cap_data <- tibble::tribble(
    ~ticker, ~date,        ~market_cap,
    "AAPL",  "2023-01-01", 2500000,
    "AAPL",  "2023-01-02", 2510000
  ) %>%
    dplyr::mutate(date = as.Date(date))

  ttm_data <- tibble::tribble(
    ~ticker, ~date,        ~totalRevenue_ttm,
    "AAPL",  "2023-01-01", 400000
  ) %>%
    dplyr::mutate(date = as.Date(date))
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
    ticker = character(0),
    date = as.Date(character(0)),
    market_cap = numeric(0)
  )

  empty_ttm <- tibble::tibble(
    ticker = character(0),
    date = as.Date(character(0)),
    totalRevenue_ttm = numeric(0)
  )
  # nolint end

  result <- join_daily_and_financial_data(empty_price, empty_market, empty_ttm)

  # Result should be empty but have proper structure
  expect_equal(nrow(result), 0)
  expect_true("ticker" %in% names(result))
  expect_true("date" %in% names(result))
})
