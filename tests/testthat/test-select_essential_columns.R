test_that("select_essential_columns selects all essential columns", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker                  = c("AAPL", "AAPL"),
    date                    = as.Date(c("2023-01-01", "2023-01-02")),
    initial_date            = as.Date(c("2022-01-01", "2022-01-01")),
    latest_date             = as.Date(c("2023-01-01", "2023-01-02")),
    fiscalDateEnding        = as.Date(c("2022-12-31", "2022-12-31")),
    reportedDate            = as.Date(c("2023-01-01", "2023-01-01")),
    calendar_quarter_ending = as.Date(c("2022-12-31", "2022-12-31")),
    open                    = c(100, 101),
    high                    = c(105, 106),
    low                     = c(99, 100),
    adjusted_close          = c(102, 103),
    volume                  = c(1000000, 1100000),
    dividend_amount         = c(0, 0),
    split_coefficient       = c(1, 1),
    n                       = c(4, 4),
    post_filing_split_multiplier = c(1, 1),
    effective_shares_outstanding = c(1e9, 1e9),
    commonStockSharesOutstanding = c(1e9, 1e9),
    market_cap              = c(102000, 103000),
    revenue_per_share       = c(10, 10),
    ebit_per_share          = c(2, 2),
    extra_column            = c("should_be_removed", "should_be_removed")
  )
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
  test_data <- tibble::tibble(
    ticker         = c("AAPL", "AAPL"),
    date           = as.Date(c("2023-01-01", "2023-01-02")),
    adjusted_close = c(102, 103),
    revenue_per_share = c(10, 10)
  )
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
  test_data <- tibble::tibble(
    ticker                  = c("AAPL"),
    date                    = as.Date("2023-01-01"),
    revenue_per_share       = 10,
    ebit_per_share          = 2,
    fcf_per_share           = 3,
    invested_capital_per_share = 50,
    other_column            = 100
  )
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
  test_data <- tibble::tibble(
    ticker         = c("AAPL"),
    other_column   = c(1),
    date           = as.Date("2023-01-01"),
    adjusted_close = c(102),
    revenue_per_share = c(10)
  )
  # nolint end

  result <- select_essential_columns(test_data)

  col_names <- names(result)
  expect_true(which(col_names == "date") < which(col_names == "ticker"))
  expect_true(which(col_names == "ticker") < which(col_names == "revenue_per_share"))
})

test_that("select_essential_columns validates input types", {
  expect_error(
    select_essential_columns("not a dataframe"),
    "^select_essential_columns\\(\\): \\[data\\] must be a data\\.frame, not character$"
  )

  expect_error(
    select_essential_columns(list(a = 1, b = 2)),
    "^select_essential_columns\\(\\): \\[data\\] must be a data\\.frame, not list$"
  )

  expect_error(
    select_essential_columns(123),
    "^select_essential_columns\\(\\): \\[data\\] must be a data\\.frame, not numeric$"
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
