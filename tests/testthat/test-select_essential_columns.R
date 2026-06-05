test_that("select_essential_columns selects all essential columns", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tribble(
    ~ticker, ~date,        ~initial_date, ~latest_date, ~fiscalDateEnding, ~reportedDate, ~calendar_quarter_ending, ~open, ~high, ~low, ~adjusted_close, ~volume,  ~dividend_amount, ~split_coefficient, ~n, ~post_filing_split_multiplier, ~effective_shares_outstanding, ~commonStockSharesOutstanding, ~market_cap, ~revenue_per_share, ~ebit_per_share, ~extra_column,
    "AAPL",  "2023-01-01", "2022-01-01",  "2023-01-01", "2022-12-31",      "2023-01-01",  "2022-12-31",             100,   105,   99,   102,             1000000, 0,                1,                  4,  1,                             1e9,                           1e9,                           102000,      10,                 2,               "should_be_removed",
    "AAPL",  "2023-01-02", "2022-01-01",  "2023-01-02", "2022-12-31",      "2023-01-01",  "2022-12-31",             101,   106,   100,  103,             1100000, 0,                1,                  4,  1,                             1e9,                           1e9,                           103000,      10,                 2,               "should_be_removed"
  ) %>%
    dplyr::mutate(dplyr::across(c(date, initial_date, latest_date, fiscalDateEnding, reportedDate, calendar_quarter_ending), as.Date))
  # nolint end

  result <- select_essential_columns(test_data)

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 2)

  expect_true("ticker" %in% names(result))
  expect_true("date" %in% names(result))
  expect_true("adjusted_close" %in% names(result))
  expect_true("revenue_per_share" %in% names(result))
  expect_true("ebit_per_share" %in% names(result))

  expect_false("extra_column" %in% names(result))
})

test_that("select_essential_columns handles missing columns gracefully", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tribble(
    ~ticker, ~date,        ~adjusted_close, ~revenue_per_share,
    "AAPL",  "2023-01-01", 102,             10,
    "AAPL",  "2023-01-02", 103,             10
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  result <- select_essential_columns(test_data)

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 2)
  expect_true("ticker" %in% names(result))
  expect_true("date" %in% names(result))
  expect_true("adjusted_close" %in% names(result))
  expect_true("revenue_per_share" %in% names(result))
})

test_that("select_essential_columns selects all per_share columns", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tribble(
    ~ticker, ~date,        ~revenue_per_share, ~ebit_per_share, ~fcf_per_share, ~invested_capital_per_share, ~other_column,
    "AAPL",  "2023-01-01", 10,                 2,               3,              50,                          100
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  result <- select_essential_columns(test_data)

  expect_true("revenue_per_share" %in% names(result))
  expect_true("ebit_per_share" %in% names(result))
  expect_true("fcf_per_share" %in% names(result))
  expect_true("invested_capital_per_share" %in% names(result))
  expect_false("other_column" %in% names(result))
})

test_that("select_essential_columns preserves column order", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tribble(
    ~ticker, ~other_column, ~date,        ~adjusted_close, ~revenue_per_share,
    "AAPL",  1,             "2023-01-01", 102,             10
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  result <- select_essential_columns(test_data)

  col_names <- names(result)
  expect_true(which(col_names == "date") < which(col_names == "ticker"))
  expect_true(
    which(col_names == "ticker") < which(col_names == "revenue_per_share")
  )
})

test_that("select_essential_columns validates input types", {
  expect_error(
    select_essential_columns("not a dataframe"),
    "^Input data must be a data\\.frame\\. Received: character$"
  )

  expect_error(
    select_essential_columns(list(a = 1, b = 2)),
    "^Input data must be a data\\.frame\\. Received: list$"
  )

  expect_error(
    select_essential_columns(123),
    "^Input data must be a data\\.frame\\. Received: numeric$"
  )
})

test_that("select_essential_columns handles empty data frame", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker = character(0),
    date   = as.Date(character(0))
  )
  # nolint end

  result <- select_essential_columns(test_data)

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
})
