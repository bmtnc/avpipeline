# Test data
test_values <- c(10, 12, 11, 13, 15, 50, 45, 14, 16, 12, 11, 13, 15, 14, 16)
test_i <- 6
test_lookback <- 4
test_lookahead <- 4
test_threshold <- 3

test_that("returns TRUE when position is anomalous", {
  actual <- detect_single_baseline_anomaly(test_i, test_values, test_lookback, test_lookahead, test_threshold)
  expected <- TRUE
  
  expect_equal(actual, expected)
})

test_that("returns FALSE when position is not anomalous", {
  actual <- detect_single_baseline_anomaly(1, test_values, test_lookback, test_lookahead, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("returns FALSE when insufficient baseline points", {
  short_values <- c(10, 12, 11, 13, 15)
  actual <- detect_single_baseline_anomaly(3, short_values, test_lookback, test_lookahead, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("returns FALSE when baseline indices is empty", {
  actual <- detect_single_baseline_anomaly(2, c(10, 12, 11, 13), lookback = 1, lookahead = 1, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("handles edge positions correctly", {
  actual_first <- detect_single_baseline_anomaly(1, test_values, test_lookback, test_lookahead, test_threshold)
  actual_last <- detect_single_baseline_anomaly(length(test_values), test_values, test_lookback, test_lookahead, test_threshold)
  
  expect_type(actual_first, "logical")
  expect_type(actual_last, "logical")
})

test_that("works with custom parameters", {
  actual <- detect_single_baseline_anomaly(8, test_values, lookback = 6, lookahead = 6, threshold = 2)
  
  expect_type(actual, "logical")
  expect_length(actual, 1)
})

test_that("handles NA values in time series", {
  values_with_na <- c(10, 12, NA, 13, 15, 50, 45, 14, 16, 12, 11, 13, 15, 14, 16)
  actual <- detect_single_baseline_anomaly(6, values_with_na, test_lookback, test_lookahead, test_threshold)
  
  expect_type(actual, "logical")
  expect_length(actual, 1)
})

test_that("handles position with NA value", {
  values_with_na <- c(10, 12, 11, 13, 15, NA, 45, 14, 16, 12, 11, 13, 15, 14, 16)
  actual <- detect_single_baseline_anomaly(6, values_with_na, test_lookback, test_lookahead, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("returns logical value", {
  actual <- detect_single_baseline_anomaly(test_i, test_values, test_lookback, test_lookahead, test_threshold)
  
  expect_type(actual, "logical")
  expect_length(actual, 1)
})

test_that("fails when i is not numeric", {
  expect_error(
    detect_single_baseline_anomaly("invalid", test_values, test_lookback, test_lookahead, test_threshold),
    "^i must be a numeric scalar \\(length 1\\)\\. Received: character of length 1$"
  )
})

test_that("fails when i is not single value", {
  expect_error(
    detect_single_baseline_anomaly(c(1, 2), test_values, test_lookback, test_lookahead, test_threshold),
    "^i must be a numeric scalar \\(length 1\\)\\. Received: numeric of length 2$"
  )
})

test_that("fails when i is less than 1", {
  expect_error(
    detect_single_baseline_anomaly(0, test_values, test_lookback, test_lookahead, test_threshold),
    "^Argument 'i' must be integer between 1 and 15, received: 0$"
  )
})

test_that("fails when i is greater than length of values", {
  expect_error(
    detect_single_baseline_anomaly(16, test_values, test_lookback, test_lookahead, test_threshold),
    "^Argument 'i' must be integer between 1 and 15, received: 16$"
  )
})

test_that("fails when values is not numeric", {
  expect_error(
    detect_single_baseline_anomaly(test_i, c("a", "b", "c"), test_lookback, test_lookahead, test_threshold),
    "^values must be a numeric vector\\. Received: character$"
  )
})

test_that("fails when values is empty vector", {
  expect_error(
    detect_single_baseline_anomaly(1, numeric(0), test_lookback, test_lookahead, test_threshold),
    "^values must not be empty$"
  )
})

test_that("fails when lookback is not numeric", {
  expect_error(
    detect_single_baseline_anomaly(test_i, test_values, "invalid", test_lookahead, test_threshold),
    "^lookback must be a numeric scalar \\(length 1\\)\\. Received: character of length 1$"
  )
})

test_that("fails when lookback is not single value", {
  expect_error(
    detect_single_baseline_anomaly(test_i, test_values, c(1, 2), test_lookahead, test_threshold),
    "^lookback must be a numeric scalar \\(length 1\\)\\. Received: numeric of length 2$"
  )
})

test_that("fails when lookback is less than 1", {
  expect_error(
    detect_single_baseline_anomaly(test_i, test_values, 0, test_lookahead, test_threshold),
    "^lookback must be >= 1\\. Received: 0$"
  )
})

test_that("fails when lookahead is not numeric", {
  expect_error(
    detect_single_baseline_anomaly(test_i, test_values, test_lookback, "invalid", test_threshold),
    "^lookahead must be a numeric scalar \\(length 1\\)\\. Received: character of length 1$"
  )
})

test_that("fails when lookahead is not single value", {
  expect_error(
    detect_single_baseline_anomaly(test_i, test_values, test_lookback, c(1, 2), test_threshold),
    "^lookahead must be a numeric scalar \\(length 1\\)\\. Received: numeric of length 2$"
  )
})

test_that("fails when lookahead is less than 1", {
  expect_error(
    detect_single_baseline_anomaly(test_i, test_values, test_lookback, 0, test_threshold),
    "^lookahead must be >= 1\\. Received: 0$"
  )
})

test_that("fails when threshold is not numeric", {
  expect_error(
    detect_single_baseline_anomaly(test_i, test_values, test_lookback, test_lookahead, "invalid"),
    "^threshold must be a numeric scalar \\(length 1\\)\\. Received: character of length 1$"
  )
})

test_that("fails when threshold is not single value", {
  expect_error(
    detect_single_baseline_anomaly(test_i, test_values, test_lookback, test_lookahead, c(1, 2)),
    "^threshold must be a numeric scalar \\(length 1\\)\\. Received: numeric of length 2$"
  )
})

test_that("fails when threshold is zero", {
  expect_error(
    detect_single_baseline_anomaly(test_i, test_values, test_lookback, test_lookahead, 0),
    "^threshold must be greater than 0\\. Received: 0$"
  )
})

test_that("fails when threshold is negative", {
  expect_error(
    detect_single_baseline_anomaly(test_i, test_values, test_lookback, test_lookahead, -1),
    "^threshold must be greater than 0\\. Received: -1$"
  )
})

test_that("fails when threshold is NA", {
  expect_error(
    detect_single_baseline_anomaly(test_i, test_values, test_lookback, test_lookahead, NA_real_),
    "^threshold must not be NA$"
  )
})

test_that("converts decimal parameters correctly", {
  actual <- detect_single_baseline_anomaly(6.0, test_values, 4.0, 4.0, 3.0)
  expected <- detect_single_baseline_anomaly(6, test_values, 4, 4, 3)
  
  expect_equal(actual, expected)
})

test_that("integrates with helper functions correctly", {
  # This test ensures the orchestration works properly
  baseline_indices <- calculate_baseline(test_i, length(test_values), test_lookback, test_lookahead)
  expect_true(length(baseline_indices) >= 6)
  
  baseline_stats <- calculate_baseline_stats(test_values, baseline_indices)
  expect_true(!is.na(baseline_stats$baseline_median))
  expect_true(!is.na(baseline_stats$baseline_mad))
  
  anomaly_result <- detect_baseline_anomaly(test_values[test_i], baseline_stats$baseline_median, 
                                           baseline_stats$baseline_mad, test_threshold)
  
  actual <- detect_single_baseline_anomaly(test_i, test_values, test_lookback, test_lookahead, test_threshold)
  expect_equal(actual, anomaly_result)
})