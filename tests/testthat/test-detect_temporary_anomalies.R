# Test data
test_values <- c(10, 12, 11, 13, 15, 50, 45, 14, 16, 12, 11, 13, 15, 14, 16)

test_that("returns logical vector of same length as input", {
  actual <- detect_temporary_anomalies(test_values)
  expected_length <- length(test_values)
  
  expect_type(actual, "logical")
  expect_length(actual, expected_length)
})

test_that("detects obvious anomalies in middle of series", {
  values <- c(10, 12, 11, 13, 15, 50, 45, 14, 16, 12, 11, 13, 15, 14, 16)
  actual <- detect_temporary_anomalies(values, threshold = 2)
  
  # Should detect positions 6 and 7 as anomalies (values 50 and 45)
  expect_true(actual[6])
  expect_true(actual[7])
  expect_false(actual[1])
  expect_false(actual[15])
})

test_that("returns all FALSE when no anomalies present", {
  values <- c(10, 11, 12, 11, 12, 13, 12, 11, 12, 13, 12, 11, 12, 13, 12)
  actual <- detect_temporary_anomalies(values)
  expected <- rep(FALSE, length(values))
  
  expect_equal(actual, expected)
})

test_that("handles NA values without error", {
  values <- c(10, 12, NA, 13, 15, 50, 45, 14, 16, 12, 11, 13, 15, 14, 16)
  actual <- detect_temporary_anomalies(values)
  
  expect_type(actual, "logical")
  expect_length(actual, length(values))
  expect_false(actual[3])  # NA position should be FALSE
})

test_that("works with custom lookback and lookahead parameters", {
  values <- c(10, 12, 11, 13, 15, 50, 45, 14, 16, 12, 11, 13, 15, 14, 16, 17, 18)
  actual <- detect_temporary_anomalies(values, lookback = 6, lookahead = 6, threshold = 2)
  
  expect_type(actual, "logical")
  expect_length(actual, length(values))
})

test_that("works with higher threshold values", {
  values <- c(10, 11, 12, 13, 14, 18, 17, 13, 12, 11, 10, 12, 13, 14, 15)
  actual <- detect_temporary_anomalies(values, threshold = 10)
  expected <- rep(FALSE, length(values))
  
  expect_equal(actual, expected)
})

test_that("fails when values is not numeric", {
  values <- c("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o")
  
  expect_error(
    detect_temporary_anomalies(values),
    "^Argument 'values' must be numeric vector, received: character$"
  )
})

test_that("fails when values is empty vector", {
  values <- numeric(0)
  
  expect_error(
    detect_temporary_anomalies(values),
    "^Argument 'values' cannot be empty vector$"
  )
})

test_that("fails when lookback is not positive integer", {
  values <- test_values
  
  expect_error(
    detect_temporary_anomalies(values, lookback = 0),
    "^Argument 'lookback' must be positive integer, received: 0$"
  )
})

test_that("fails when lookback is negative", {
  values <- test_values
  
  expect_error(
    detect_temporary_anomalies(values, lookback = -1),
    "^Argument 'lookback' must be positive integer, received: -1$"
  )
})

test_that("fails when lookback is not numeric", {
  values <- test_values
  
  expect_error(
    detect_temporary_anomalies(values, lookback = "invalid"),
    "^Argument 'lookback' must be positive integer, received: invalid$"
  )
})

test_that("fails when lookahead is not positive integer", {
  values <- test_values
  
  expect_error(
    detect_temporary_anomalies(values, lookahead = 0),
    "^Argument 'lookahead' must be positive integer, received: 0$"
  )
})

test_that("fails when lookahead is negative", {
  values <- test_values
  
  expect_error(
    detect_temporary_anomalies(values, lookahead = -2),
    "^Argument 'lookahead' must be positive integer, received: -2$"
  )
})

test_that("fails when lookahead is not numeric", {
  values <- test_values
  
  expect_error(
    detect_temporary_anomalies(values, lookahead = TRUE),
    "^Argument 'lookahead' must be positive integer, received: TRUE$"
  )
})

test_that("fails when threshold is not positive", {
  values <- test_values
  
  expect_error(
    detect_temporary_anomalies(values, threshold = 0),
    "^Argument 'threshold' must be positive numeric, received: 0$"
  )
})

test_that("fails when threshold is negative", {
  values <- test_values
  
  expect_error(
    detect_temporary_anomalies(values, threshold = -1),
    "^Argument 'threshold' must be positive numeric, received: -1$"
  )
})

test_that("fails when threshold is not numeric", {
  values <- test_values
  
  expect_error(
    detect_temporary_anomalies(values, threshold = "invalid"),
    "^Argument 'threshold' must be positive numeric, received: invalid$"
  )
})

test_that("fails when insufficient data for given parameters", {
  values <- c(1, 2, 3, 4, 5)  # Only 5 values
  
  expect_error(
    detect_temporary_anomalies(values, lookback = 4, lookahead = 4),
    "^Insufficient data: need at least 11 observations for lookback=4 and lookahead=4, received: 5$"
  )
})

test_that("handles minimum required data length", {
  values <- c(10, 12, 11, 13, 15, 50, 45, 14, 16, 12, 11)  # Exactly 11 values
  actual <- detect_temporary_anomalies(values, lookback = 4, lookahead = 4)
  
  expect_type(actual, "logical")
  expect_length(actual, 11)
})

test_that("converts integer parameters correctly", {
  values <- test_values
  actual <- detect_temporary_anomalies(values, lookback = 4.0, lookahead = 4.0, threshold = 3.0)
  
  expect_type(actual, "logical")
  expect_length(actual, length(values))
})