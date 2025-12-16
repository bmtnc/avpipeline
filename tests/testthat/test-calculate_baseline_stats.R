# Test data
test_values <- c(10, 12, 11, 13, 15, 50, 45, 14, 16, 12, 11, 13, 15, 14, 16)
test_indices <- c(1, 2, 3, 4, 5)

test_that("returns named list with correct structure", {
  actual <- calculate_baseline_stats(test_values, test_indices)
  
  expect_type(actual, "list")
  expect_named(actual, c("baseline_median", "baseline_mad"))
  expect_length(actual, 2)
})

test_that("calculates correct median and MAD for normal values", {
  values <- c(10, 12, 11, 13, 15, 14, 16, 12, 11, 13)
  indices <- c(1, 2, 3, 4, 5)
  actual <- calculate_baseline_stats(values, indices)
  expected_median <- median(c(10, 12, 11, 13, 15))
  expected_mad <- mad(c(10, 12, 11, 13, 15))
  
  expect_equal(actual$baseline_median, expected_median)
  expect_equal(actual$baseline_mad, expected_mad)
})

test_that("handles single index correctly", {
  actual <- calculate_baseline_stats(test_values, c(5))
  expected_median <- 15
  expected_mad <- 0
  
  expect_equal(actual$baseline_median, expected_median)
  expect_equal(actual$baseline_mad, expected_mad)
})

test_that("handles duplicate indices correctly", {
  actual <- calculate_baseline_stats(test_values, c(1, 1, 2, 2))
  expected_median <- median(c(10, 10, 12, 12))
  expected_mad <- mad(c(10, 10, 12, 12))
  
  expect_equal(actual$baseline_median, expected_median)
  expect_equal(actual$baseline_mad, expected_mad)
})

test_that("handles values with NA using na.rm = TRUE", {
  values <- c(10, 12, NA, 13, 15, 14, 16, 12, 11, 13)
  indices <- c(1, 2, 3, 4, 5)
  actual <- calculate_baseline_stats(values, indices)
  expected_median <- median(c(10, 12, NA, 13, 15), na.rm = TRUE)
  expected_mad <- mad(c(10, 12, NA, 13, 15), na.rm = TRUE)
  
  expect_equal(actual$baseline_median, expected_median)
  expect_equal(actual$baseline_mad, expected_mad)
})

test_that("handles all NA values in baseline", {
  values <- c(NA, NA, NA, 13, 15, 14, 16, 12, 11, 13)
  indices <- c(1, 2, 3)
  actual <- calculate_baseline_stats(values, indices)
  
  expect_true(is.na(actual$baseline_median))
  expect_true(is.na(actual$baseline_mad))
})

test_that("works with non-consecutive indices", {
  indices <- c(1, 3, 5, 7, 9)
  actual <- calculate_baseline_stats(test_values, indices)
  expected_values <- test_values[indices]
  expected_median <- median(expected_values)
  expected_mad <- mad(expected_values)
  
  expect_equal(actual$baseline_median, expected_median)
  expect_equal(actual$baseline_mad, expected_mad)
})

test_that("fails when values is not numeric", {
  values <- c("a", "b", "c", "d", "e")

  expect_error(
    calculate_baseline_stats(values, test_indices),
    "^values must be a numeric vector\\. Received: character$"
  )
})

test_that("fails when values is empty vector", {
  values <- numeric(0)
  
  expect_error(
    calculate_baseline_stats(values, c(1)),
    "^Argument 'indices' contains out-of-bounds values\\. Valid range: 1 to 0$"
  )
})

test_that("fails when indices is not numeric", {
  expect_error(
    calculate_baseline_stats(test_values, c("a", "b")),
    "^indices must be a numeric vector\\. Received: character$"
  )
})

test_that("fails when indices is empty vector", {
  expect_error(
    calculate_baseline_stats(test_values, numeric(0)),
    "^indices must not be empty$"
  )
})

test_that("fails when indices is empty integer vector", {
  expect_error(
    calculate_baseline_stats(test_values, integer(0)),
    "^indices must not be empty$"
  )
})

test_that("fails when indices contains values less than 1", {
  expect_error(
    calculate_baseline_stats(test_values, c(0, 1, 2)),
    "^Argument 'indices' contains out-of-bounds values\\. Valid range: 1 to 15$"
  )
})

test_that("fails when indices contains values greater than length of values", {
  expect_error(
    calculate_baseline_stats(test_values, c(1, 2, 16)),
    "^Argument 'indices' contains out-of-bounds values\\. Valid range: 1 to 15$"
  )
})

test_that("fails when indices contains negative values", {
  expect_error(
    calculate_baseline_stats(test_values, c(-1, 1, 2)),
    "^Argument 'indices' contains out-of-bounds values\\. Valid range: 1 to 15$"
  )
})

test_that("fails when indices contains both under and over bounds", {
  expect_error(
    calculate_baseline_stats(test_values, c(0, 1, 2, 16)),
    "^Argument 'indices' contains out-of-bounds values\\. Valid range: 1 to 15$"
  )
})

test_that("handles decimal indices by converting to integer", {
  actual <- calculate_baseline_stats(test_values, c(1.0, 2.0, 3.0))
  expected <- calculate_baseline_stats(test_values, c(1, 2, 3))
  
  expect_equal(actual, expected)
})

test_that("returns numeric values for median and mad", {
  actual <- calculate_baseline_stats(test_values, test_indices)
  
  expect_type(actual$baseline_median, "double")
  expect_type(actual$baseline_mad, "double")
})

test_that("handles identical values correctly", {
  values <- c(10, 10, 10, 10, 10, 10, 10, 10, 10, 10)
  indices <- c(1, 2, 3, 4, 5)
  actual <- calculate_baseline_stats(values, indices)
  
  expect_equal(actual$baseline_median, 10)
  expect_equal(actual$baseline_mad, 0)
})

test_that("handles maximum length indices vector", {
  indices <- seq_along(test_values)
  actual <- calculate_baseline_stats(test_values, indices)
  expected_median <- median(test_values)
  expected_mad <- mad(test_values)
  
  expect_equal(actual$baseline_median, expected_median)
  expect_equal(actual$baseline_mad, expected_mad)
})