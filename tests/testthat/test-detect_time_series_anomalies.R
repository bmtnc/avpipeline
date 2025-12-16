# Test data setup
test_values <- c(1, 2, 3, 4, 5, 100, 6, 7, 8, 9, 10)  # 100 should be anomalous
test_values_normal <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)  # No anomalies
test_values_same <- rep(5, 15)  # All same values
test_values_with_na <- c(1, 2, 3, NA, 5, 6, 7, 8, 9, 10, 11)
test_values_short <- c(1, 2, 3)  # Too few observations

testthat::test_that("normal operation detects anomalies correctly", {
  actual <- detect_time_series_anomalies(test_values)
  expected <- c(FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE)
  testthat::expect_equal(actual, expected)
})

testthat::test_that("normal operation with no anomalies returns all FALSE", {
  actual <- detect_time_series_anomalies(test_values_normal)
  expected <- rep(FALSE, length(test_values_normal))
  testthat::expect_equal(actual, expected)
})

testthat::test_that("all same values returns all FALSE", {
  actual <- detect_time_series_anomalies(test_values_same)
  expected <- rep(FALSE, length(test_values_same))
  testthat::expect_equal(actual, expected)
})

testthat::test_that("custom threshold works correctly", {
  actual <- detect_time_series_anomalies(test_values, threshold = 1)
  # With lower threshold, more values should be flagged as anomalous
  testthat::expect_true(sum(actual) >= 1)
})

testthat::test_that("custom min_observations works correctly", {
  actual <- detect_time_series_anomalies(test_values, min_observations = 5)
  testthat::expect_length(actual, length(test_values))
})

testthat::test_that("empty input returns empty logical vector", {
  actual <- detect_time_series_anomalies(numeric(0))
  expected <- logical(0)
  testthat::expect_equal(actual, expected)
})

testthat::test_that("non-numeric values argument fails", {
  testthat::expect_error(
    detect_time_series_anomalies(c("a", "b", "c")),
    "^Argument 'values' must be numeric\\. Received: character$"
  )
})

testthat::test_that("non-numeric threshold fails", {
  testthat::expect_error(
    detect_time_series_anomalies(test_values, threshold = "3"),
    "^threshold must be a numeric scalar \\(length 1\\)\\. Received: character of length 1$"
  )
})

testthat::test_that("multiple threshold values fail", {
  testthat::expect_error(
    detect_time_series_anomalies(test_values, threshold = c(2, 3)),
    "^threshold must be a numeric scalar \\(length 1\\)\\. Received: numeric of length 2$"
  )
})

testthat::test_that("non-positive threshold fails", {
  testthat::expect_error(
    detect_time_series_anomalies(test_values, threshold = -1),
    "^threshold must be greater than 0\\. Received: -1$"
  )
})

testthat::test_that("zero threshold fails", {
  testthat::expect_error(
    detect_time_series_anomalies(test_values, threshold = 0),
    "^threshold must be greater than 0\\. Received: 0$"
  )
})

testthat::test_that("non-numeric min_observations fails", {
  testthat::expect_error(
    detect_time_series_anomalies(test_values, min_observations = "10"),
    "^min_observations must be a numeric scalar \\(length 1\\)\\. Received: character of length 1$"
  )
})

testthat::test_that("multiple min_observations values fail", {
  testthat::expect_error(
    detect_time_series_anomalies(test_values, min_observations = c(5, 10)),
    "^min_observations must be a numeric scalar \\(length 1\\)\\. Received: numeric of length 2$"
  )
})

testthat::test_that("non-positive min_observations fails", {
  testthat::expect_error(
    detect_time_series_anomalies(test_values, min_observations = 0),
    "^min_observations must be >= 1\\. Received: 0$"
  )
})

testthat::test_that("NA values in input fail", {
  testthat::expect_error(
    detect_time_series_anomalies(test_values_with_na),
    "^Argument 'values' contains NA values\\. Found 1 NA values out of 11 total values\\.$"
  )
})

testthat::test_that("insufficient observations fail", {
  testthat::expect_error(
    detect_time_series_anomalies(test_values_short),
    "^Insufficient observations for anomaly detection\\. Need at least 10 but got 3\\.$"
  )
})

testthat::test_that("insufficient observations with custom min_observations fail", {
  testthat::expect_error(
    detect_time_series_anomalies(test_values_short, min_observations = 5),
    "^Insufficient observations for anomaly detection\\. Need at least 5 but got 3\\.$"
  )
})