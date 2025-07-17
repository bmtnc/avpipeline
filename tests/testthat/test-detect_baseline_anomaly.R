# Test data
test_value <- 50
test_baseline_median <- 12
test_baseline_mad <- 2
test_threshold <- 3

test_that("returns TRUE when value is anomalous", {
  actual <- detect_baseline_anomaly(test_value, test_baseline_median, test_baseline_mad, test_threshold)
  expected <- TRUE
  
  expect_equal(actual, expected)
})

test_that("returns FALSE when value is not anomalous", {
  actual <- detect_baseline_anomaly(14, test_baseline_median, test_baseline_mad, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("returns FALSE when value equals baseline median", {
  actual <- detect_baseline_anomaly(test_baseline_median, test_baseline_median, test_baseline_mad, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("returns FALSE when value is exactly at threshold boundary", {
  boundary_value <- test_baseline_median + (test_threshold * test_baseline_mad)
  actual <- detect_baseline_anomaly(boundary_value, test_baseline_median, test_baseline_mad, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("returns TRUE when value is slightly above threshold boundary", {
  above_boundary_value <- test_baseline_median + (test_threshold * test_baseline_mad) + 0.001
  actual <- detect_baseline_anomaly(above_boundary_value, test_baseline_median, test_baseline_mad, test_threshold)
  expected <- TRUE
  
  expect_equal(actual, expected)
})

test_that("returns FALSE when value is slightly below threshold boundary", {
  below_boundary_value <- test_baseline_median + (test_threshold * test_baseline_mad) - 0.001
  actual <- detect_baseline_anomaly(below_boundary_value, test_baseline_median, test_baseline_mad, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("handles negative values correctly", {
  actual <- detect_baseline_anomaly(-50, test_baseline_median, test_baseline_mad, test_threshold)
  expected <- TRUE
  
  expect_equal(actual, expected)
})

test_that("handles negative baseline median correctly", {
  actual <- detect_baseline_anomaly(50, -10, test_baseline_mad, test_threshold)
  expected <- TRUE
  
  expect_equal(actual, expected)
})

test_that("returns FALSE when value is NA", {
  actual <- detect_baseline_anomaly(NA_real_, test_baseline_median, test_baseline_mad, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("returns FALSE when baseline_mad is zero", {
  actual <- detect_baseline_anomaly(test_value, test_baseline_median, 0, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("returns FALSE when baseline_mad is negative", {
  actual <- detect_baseline_anomaly(test_value, test_baseline_median, -1, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("returns FALSE when baseline_median is NA", {
  actual <- detect_baseline_anomaly(test_value, NA_real_, test_baseline_mad, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("returns FALSE when baseline_mad is NA", {
  actual <- detect_baseline_anomaly(test_value, test_baseline_median, NA_real_, test_threshold)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("works with very small MAD values", {
  small_mad <- 0.001
  anomalous_value <- test_baseline_median + 0.004  # 0.004 > 0.003 (3 * 0.001)
  actual <- detect_baseline_anomaly(anomalous_value, test_baseline_median, small_mad, test_threshold)
  expected <- TRUE
  
  expect_equal(actual, expected)
})

test_that("works with very large threshold values", {
  actual <- detect_baseline_anomaly(test_value, test_baseline_median, test_baseline_mad, 100)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("fails when value is not numeric", {
  expect_error(
    detect_baseline_anomaly("invalid", test_baseline_median, test_baseline_mad, test_threshold),
    "^Argument 'value' must be single numeric value, received: character of length 1$"
  )
})

test_that("fails when value is not single value", {
  expect_error(
    detect_baseline_anomaly(c(1, 2), test_baseline_median, test_baseline_mad, test_threshold),
    "^Argument 'value' must be single numeric value, received: numeric of length 2$"
  )
})

test_that("fails when baseline_median is not numeric", {
  expect_error(
    detect_baseline_anomaly(test_value, "invalid", test_baseline_mad, test_threshold),
    "^Argument 'baseline_median' must be single numeric value, received: character of length 1$"
  )
})

test_that("fails when baseline_median is not single value", {
  expect_error(
    detect_baseline_anomaly(test_value, c(1, 2), test_baseline_mad, test_threshold),
    "^Argument 'baseline_median' must be single numeric value, received: numeric of length 2$"
  )
})

test_that("fails when baseline_mad is not numeric", {
  expect_error(
    detect_baseline_anomaly(test_value, test_baseline_median, "invalid", test_threshold),
    "^Argument 'baseline_mad' must be single numeric value, received: character of length 1$"
  )
})

test_that("fails when baseline_mad is not single value", {
  expect_error(
    detect_baseline_anomaly(test_value, test_baseline_median, c(1, 2), test_threshold),
    "^Argument 'baseline_mad' must be single numeric value, received: numeric of length 2$"
  )
})

test_that("fails when threshold is not numeric", {
  expect_error(
    detect_baseline_anomaly(test_value, test_baseline_median, test_baseline_mad, "invalid"),
    "^Argument 'threshold' must be positive numeric value, received: invalid$"
  )
})

test_that("fails when threshold is not single value", {
  expect_error(
    detect_baseline_anomaly(test_value, test_baseline_median, test_baseline_mad, c(1, 2)),
    "^Argument 'threshold' must be positive numeric value, received: 1, 2$"
  )
})

test_that("fails when threshold is zero", {
  expect_error(
    detect_baseline_anomaly(test_value, test_baseline_median, test_baseline_mad, 0),
    "^Argument 'threshold' must be positive numeric value, received: 0$"
  )
})

test_that("fails when threshold is negative", {
  expect_error(
    detect_baseline_anomaly(test_value, test_baseline_median, test_baseline_mad, -1),
    "^Argument 'threshold' must be positive numeric value, received: -1$"
  )
})

test_that("fails when threshold is NA", {
  expect_error(
    detect_baseline_anomaly(test_value, test_baseline_median, test_baseline_mad, NA_real_),
    "^Argument 'threshold' must be positive numeric value, received: NA$"
  )
})

test_that("returns logical value", {
  actual <- detect_baseline_anomaly(test_value, test_baseline_median, test_baseline_mad, test_threshold)
  
  expect_type(actual, "logical")
  expect_length(actual, 1)
})

test_that("handles decimal inputs correctly", {
  actual <- detect_baseline_anomaly(12.5, 12.0, 2.5, 3.0)
  expected <- FALSE
  
  expect_equal(actual, expected)
})

test_that("calculation is symmetric for positive and negative deviations", {
  positive_deviation <- test_baseline_median + 10
  negative_deviation <- test_baseline_median - 10
  
  actual_positive <- detect_baseline_anomaly(positive_deviation, test_baseline_median, test_baseline_mad, test_threshold)
  actual_negative <- detect_baseline_anomaly(negative_deviation, test_baseline_median, test_baseline_mad, test_threshold)
  
  expect_equal(actual_positive, actual_negative)
})