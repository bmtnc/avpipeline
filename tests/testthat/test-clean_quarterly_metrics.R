# Test data for clean_quarterly_metrics function
test_df <- tibble::tribble(
  ~ticker, ~date, ~revenue, ~shares,
  "AAPL", as.Date("2020-03-31"), 100, 1000,
  "AAPL", as.Date("2020-06-30"), 110, 1100,
  "AAPL", as.Date("2020-09-30"), 120, 1200,
  "AAPL", as.Date("2020-12-31"), 500, 5000,  # Anomaly
  "AAPL", as.Date("2021-03-31"), 480, 4800,  # Anomaly
  "AAPL", as.Date("2021-06-30"), 130, 1300,
  "AAPL", as.Date("2021-09-30"), 140, 1400,
  "AAPL", as.Date("2021-12-31"), 150, 1500,
  "AAPL", as.Date("2022-03-31"), 160, 1600,
  "AAPL", as.Date("2022-06-30"), 170, 1700,
  "AAPL", as.Date("2022-09-30"), 180, 1800,
  "AAPL", as.Date("2022-12-31"), 190, 1900,
  "MSFT", as.Date("2020-03-31"), 200, 2000,
  "MSFT", as.Date("2020-06-30"), 210, 2100,
  "MSFT", as.Date("2020-09-30"), 220, 2200,
  "MSFT", as.Date("2020-12-31"), 230, 2300,
  "MSFT", as.Date("2021-03-31"), 240, 2400,
  "MSFT", as.Date("2021-06-30"), 250, 2500,
  "MSFT", as.Date("2021-09-30"), 260, 2600,
  "MSFT", as.Date("2021-12-31"), 270, 2700,
  "MSFT", as.Date("2022-03-31"), 280, 2800,
  "MSFT", as.Date("2022-06-30"), 290, 2900,
  "MSFT", as.Date("2022-09-30"), 300, 3000,
  "MSFT", as.Date("2022-12-31"), 310, 3100
)

test_that("returns cleaned data frame with anomaly flag columns", {
  actual <- clean_quarterly_metrics(
    data = test_df,
    metric_cols = c("revenue", "shares"),
    date_col = "date",
    ticker_col = "ticker",
    threshold = 2
  )
  
  expect_s3_class(actual, "data.frame")
  expect_true("revenue_anomaly" %in% names(actual))
  expect_true("shares_anomaly" %in% names(actual))
  expect_true("revenue" %in% names(actual))
  expect_true("shares" %in% names(actual))
})

test_that("works with single metric column", {
  actual <- clean_quarterly_metrics(
    data = test_df,
    metric_cols = "revenue",
    date_col = "date",
    ticker_col = "ticker"
  )
  
  expect_true("revenue" %in% names(actual))
  expect_true("revenue_anomaly" %in% names(actual))
  expect_false("shares" %in% names(actual))
})

test_that("works with custom threshold parameters", {
  actual <- clean_quarterly_metrics(
    data = test_df,
    metric_cols = c("revenue", "shares"),
    date_col = "date",
    ticker_col = "ticker",
    threshold = 5,
    lookback = 3,
    lookahead = 3
  )
  
  expect_s3_class(actual, "data.frame")
  expect_true(nrow(actual) > 0)
})

test_that("handles empty data frame gracefully", {
  empty_df <- test_df %>% dplyr::slice(0)
  
  actual <- clean_quarterly_metrics(
    data = empty_df,
    metric_cols = c("revenue", "shares"),
    date_col = "date",
    ticker_col = "ticker"
  )
  
  expect_equal(nrow(actual), 0)
  expect_true("revenue" %in% names(actual))
  expect_true("shares" %in% names(actual))
})

test_that("fails when metric_cols is not character vector", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = 123,
      date_col = "date",
      ticker_col = "ticker"
    ),
    "^Argument 'metric_cols' must be non-empty character vector, received: numeric of length 1$"
  )
})

test_that("fails when metric_cols is empty vector", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = character(0),
      date_col = "date",
      ticker_col = "ticker"
    ),
    "^Argument 'metric_cols' must be non-empty character vector, received: character of length 0$"
  )
})

test_that("fails when date_col is not single character string", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = "revenue",
      date_col = c("date1", "date2"),
      ticker_col = "ticker"
    ),
    "^Argument 'date_col' must be single character string, received: character of length 2$"
  )
})

test_that("fails when date_col is not character", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = "revenue",
      date_col = 123,
      ticker_col = "ticker"
    ),
    "^Argument 'date_col' must be single character string, received: numeric of length 1$"
  )
})

test_that("fails when ticker_col is not single character string", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = "revenue",
      date_col = "date",
      ticker_col = c("ticker1", "ticker2")
    ),
    "^Argument 'ticker_col' must be single character string, received: character of length 2$"
  )
})

test_that("fails when ticker_col is not character", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = "revenue",
      date_col = "date",
      ticker_col = TRUE
    ),
    "^Argument 'ticker_col' must be single character string, received: logical of length 1$"
  )
})

test_that("fails when threshold is not positive numeric", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = "revenue",
      date_col = "date",
      ticker_col = "ticker",
      threshold = 0
    ),
    "^Argument 'threshold' must be positive numeric, received: 0$"
  )
})

test_that("fails when threshold is negative", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = "revenue",
      date_col = "date",
      ticker_col = "ticker",
      threshold = -1
    ),
    "^Argument 'threshold' must be positive numeric, received: -1$"
  )
})

test_that("fails when threshold is not numeric", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = "revenue",
      date_col = "date",
      ticker_col = "ticker",
      threshold = "invalid"
    ),
    "^Argument 'threshold' must be positive numeric, received: invalid$"
  )
})

test_that("fails when lookback is not positive integer", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = "revenue",
      date_col = "date",
      ticker_col = "ticker",
      lookback = 0
    ),
    "^Argument 'lookback' must be positive integer, received: 0$"
  )
})

test_that("fails when lookback is negative", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = "revenue",
      date_col = "date",
      ticker_col = "ticker",
      lookback = -2
    ),
    "^Argument 'lookback' must be positive integer, received: -2$"
  )
})

test_that("fails when lookahead is not positive integer", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = "revenue",
      date_col = "date",
      ticker_col = "ticker",
      lookahead = 0
    ),
    "^Argument 'lookahead' must be positive integer, received: 0$"
  )
})

test_that("fails when lookahead is negative", {
  expect_error(
    clean_quarterly_metrics(
      data = test_df,
      metric_cols = "revenue",
      date_col = "date",
      ticker_col = "ticker",
      lookahead = -3
    ),
    "^Argument 'lookahead' must be positive integer, received: -3$"
  )
})

test_that("converts numeric parameters to integers correctly", {
  actual <- clean_quarterly_metrics(
    data = test_df,
    metric_cols = "revenue",
    date_col = "date",
    ticker_col = "ticker",
    threshold = 3.0,
    lookback = 4.0,
    lookahead = 4.0
  )
  
  expect_s3_class(actual, "data.frame")
  expect_true(nrow(actual) > 0)
})