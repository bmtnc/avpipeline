# Test data
test_df <- tibble::tribble(
  ~ticker, ~date, ~metric1, ~metric2,
  "AAPL", "2020-03-31", 10, 100,
  "AAPL", "2020-06-30", 12, 110,
  "AAPL", "2020-09-30", 11, 105,
  "AAPL", "2020-12-31", 13, 115,
  "AAPL", "2021-03-31", 15, 120,
  "AAPL", "2021-06-30", 50, 500,  # Anomaly
  "AAPL", "2021-09-30", 45, 450,  # Anomaly
  "AAPL", "2021-12-31", 14, 125,
  "AAPL", "2022-03-31", 16, 130,
  "AAPL", "2022-06-30", 12, 135,
  "AAPL", "2022-09-30", 11, 140,
  "AAPL", "2022-12-31", 13, 145,
  "AAPL", "2023-03-31", 15, 150,
  "AAPL", "2023-06-30", 14, 155,
  "AAPL", "2023-09-30", 16, 160
)

test_that("returns data frame with anomaly flag columns added", {
  actual <- add_anomaly_flag_columns(test_df, c("metric1", "metric2"))
  
  expect_true(is.data.frame(actual))
  expect_true("metric1_anomaly" %in% names(actual))
  expect_true("metric2_anomaly" %in% names(actual))
  expect_type(actual$metric1_anomaly, "logical")
  expect_type(actual$metric2_anomaly, "logical")
})

test_that("preserves original data columns", {
  actual <- add_anomaly_flag_columns(test_df, c("metric1", "metric2"))
  
  expect_equal(actual$ticker, test_df$ticker)
  expect_equal(actual$date, test_df$date)
  expect_equal(actual$metric1, test_df$metric1)
  expect_equal(actual$metric2, test_df$metric2)
})

test_that("detects anomalies in metric columns", {
  actual <- add_anomaly_flag_columns(test_df, c("metric1", "metric2"), threshold = 2)
  
  # Should detect anomalies at positions 6 and 7 (values 50, 45 for metric1 and 500, 450 for metric2)
  expect_true(actual$metric1_anomaly[6])
  expect_true(actual$metric1_anomaly[7])
  expect_true(actual$metric2_anomaly[6])
  expect_true(actual$metric2_anomaly[7])
  
  # Should not detect anomalies in normal values
  expect_false(actual$metric1_anomaly[1])
  expect_false(actual$metric1_anomaly[15])
  expect_false(actual$metric2_anomaly[1])
  expect_false(actual$metric2_anomaly[15])
})

test_that("works with single metric column", {
  actual <- add_anomaly_flag_columns(test_df, "metric1")
  
  expect_true("metric1_anomaly" %in% names(actual))
  expect_false("metric2_anomaly" %in% names(actual))
  expect_type(actual$metric1_anomaly, "logical")
})

test_that("works with custom threshold parameter", {
  actual <- add_anomaly_flag_columns(test_df, c("metric1"), threshold = 50)
  
  expect_false(any(actual$metric1_anomaly))
})

test_that("works with custom lookback parameter", {
  actual <- add_anomaly_flag_columns(test_df, c("metric1"), lookback = 6)
  
  expect_true("metric1_anomaly" %in% names(actual))
  expect_type(actual$metric1_anomaly, "logical")
})

test_that("works with custom lookahead parameter", {
  actual <- add_anomaly_flag_columns(test_df, c("metric1"), lookahead = 6)
  
  expect_true("metric1_anomaly" %in% names(actual))
  expect_type(actual$metric1_anomaly, "logical")
})

test_that("handles NA values in metric columns", {
  test_df_na <- test_df
  test_df_na$metric1[3] <- NA
  
  actual <- add_anomaly_flag_columns(test_df_na, c("metric1"))
  
  expect_true("metric1_anomaly" %in% names(actual))
  expect_false(actual$metric1_anomaly[3])  # NA position should be FALSE
})

test_that("adds FALSE anomaly columns when detection fails", {
  # Create data with insufficient observations to cause failure
  small_df <- test_df[1:5, ]
  
  # Capture output to suppress error messages
  actual <- capture.output(
    result <- add_anomaly_flag_columns(small_df, c("metric1"), lookback = 4, lookahead = 4),
    type = "message"
  )
  
  expect_true("metric1_anomaly" %in% names(result))
  expect_false(any(result$metric1_anomaly))  # Should all be FALSE due to failure
})

test_that("continues processing other columns when one fails", {
  # Create mixed data where one column might fail
  mixed_df <- test_df
  mixed_df$metric_small <- c(rep(1, 5), rep(NA, 10))  # Not enough valid data
  
  actual <- capture.output(
    result <- add_anomaly_flag_columns(mixed_df, c("metric1", "metric_small")),
    type = "message"
  )
  
  expect_true("metric1_anomaly" %in% names(result))
  expect_true("metric_small_anomaly" %in% names(result))
})

test_that("fails when metric_cols is not character vector", {
  expect_error(
    add_anomaly_flag_columns(test_df, c(1, 2)),
    "^Argument 'metric_cols' must be non-empty character vector, received: numeric of length 2$"
  )
})

test_that("fails when metric_cols is empty", {
  expect_error(
    add_anomaly_flag_columns(test_df, character(0)),
    "^metric_cols must not be empty \\(length 0\\)$"
  )
})

test_that("fails when threshold is not positive numeric", {
  expect_error(
    add_anomaly_flag_columns(test_df, c("metric1"), threshold = 0),
    "^threshold must be greater than 0\\. Received: 0$"
  )
})

test_that("fails when threshold is negative", {
  expect_error(
    add_anomaly_flag_columns(test_df, c("metric1"), threshold = -1),
    "^threshold must be greater than 0\\. Received: -1$"
  )
})

test_that("fails when threshold is not numeric", {
  expect_error(
    add_anomaly_flag_columns(test_df, c("metric1"), threshold = "invalid"),
    "^threshold must be a numeric scalar \\(length 1\\)\\. Received: character of length 1$"
  )
})

test_that("fails when lookback is not positive integer", {
  expect_error(
    add_anomaly_flag_columns(test_df, c("metric1"), lookback = 0),
    "^lookback must be greater than 0\\. Received: 0$"
  )
})

test_that("fails when lookback is negative", {
  expect_error(
    add_anomaly_flag_columns(test_df, c("metric1"), lookback = -1),
    "^lookback must be greater than 0\\. Received: -1$"
  )
})

test_that("fails when lookback is not numeric", {
  expect_error(
    add_anomaly_flag_columns(test_df, c("metric1"), lookback = "invalid"),
    "^lookback must be a numeric scalar \\(length 1\\)\\. Received: character of length 1$"
  )
})

test_that("fails when lookahead is not positive integer", {
  expect_error(
    add_anomaly_flag_columns(test_df, c("metric1"), lookahead = 0),
    "^lookahead must be greater than 0\\. Received: 0$"
  )
})

test_that("fails when lookahead is negative", {
  expect_error(
    add_anomaly_flag_columns(test_df, c("metric1"), lookahead = -2),
    "^lookahead must be greater than 0\\. Received: -2$"
  )
})

test_that("fails when lookahead is not numeric", {
  expect_error(
    add_anomaly_flag_columns(test_df, c("metric1"), lookahead = TRUE),
    "^lookahead must be a numeric scalar \\(length 1\\)\\. Received: logical of length 1$"
  )
})

test_that("converts numeric parameters to appropriate types", {
  actual <- add_anomaly_flag_columns(test_df, c("metric1"), 
                                     threshold = 3.0, lookback = 4.0, lookahead = 4.0)
  
  expect_true("metric1_anomaly" %in% names(actual))
  expect_type(actual$metric1_anomaly, "logical")
})