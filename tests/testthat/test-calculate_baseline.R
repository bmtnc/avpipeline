# Test data
test_n <- 15
test_lookback <- 4
test_lookahead <- 4

test_that("returns correct indices for middle position", {
  actual <- calculate_baseline(8, test_n, test_lookback, test_lookahead)
  expected <- c(4, 5, 6, 10, 11, 12)
  
  expect_equal(actual, expected)
})

test_that("returns correct indices for position near beginning", {
  actual <- calculate_baseline(3, test_n, test_lookback, test_lookahead)
  expected <- c(1, 5, 6, 7)
  
  expect_equal(actual, expected)
})

test_that("returns correct indices for position near end", {
  actual <- calculate_baseline(13, test_n, test_lookback, test_lookahead)
  expected <- c(9, 10, 11, 15)
  
  expect_equal(actual, expected)
})

test_that("returns correct indices for first position", {
  actual <- calculate_baseline(1, test_n, test_lookback, test_lookahead)
  expected <- c(3, 4, 5)
  
  expect_equal(actual, expected)
})

test_that("returns correct indices for last position", {
  actual <- calculate_baseline(test_n, test_n, test_lookback, test_lookahead)
  expected <- c(11, 12, 13)
  
  expect_equal(actual, expected)
})

test_that("handles custom lookback and lookahead parameters", {
  actual <- calculate_baseline(8, test_n, lookback = 6, lookahead = 6)
  expected <- c(2, 3, 4, 5, 6, 10, 11, 12, 13, 14)
  
  expect_equal(actual, expected)
})

test_that("returns empty vector when no valid indices available", {
  actual <- calculate_baseline(2, 4, lookback = 1, lookahead = 1)
  expected <- integer(0)
  
  expect_equal(actual, expected)
})

test_that("excludes current point and immediate neighbors", {
  actual <- calculate_baseline(8, test_n, test_lookback, test_lookahead)
  excluded_indices <- c(7, 8, 9)
  
  expect_true(all(!excluded_indices %in% actual))
})

test_that("fails when i is not numeric", {
  expect_error(
    calculate_baseline("invalid", test_n, test_lookback, test_lookahead),
    "^Argument 'i' must be single numeric value, received: invalid$"
  )
})

test_that("fails when i is not single value", {
  expect_error(
    calculate_baseline(c(1, 2), test_n, test_lookback, test_lookahead),
    "^Argument 'i' must be single numeric value, received: 1, 2$"
  )
})

test_that("fails when i is less than 1", {
  expect_error(
    calculate_baseline(0, test_n, test_lookback, test_lookahead),
    "^Argument 'i' must be integer between 1 and 15, received: 0$"
  )
})

test_that("fails when i is greater than n", {
  expect_error(
    calculate_baseline(16, test_n, test_lookback, test_lookahead),
    "^Argument 'i' must be integer between 1 and 15, received: 16$"
  )
})

test_that("fails when n is not numeric", {
  expect_error(
    calculate_baseline(8, "invalid", test_lookback, test_lookahead),
    "^Argument 'n' must be single numeric value, received: invalid$"
  )
})

test_that("fails when n is not single value", {
  expect_error(
    calculate_baseline(8, c(10, 15), test_lookback, test_lookahead),
    "^Argument 'n' must be single numeric value, received: 10, 15$"
  )
})

test_that("fails when n is less than 1", {
  expect_error(
    calculate_baseline(8, 0, test_lookback, test_lookahead),
    "^Argument 'n' must be positive integer, received: 0$"
  )
})

test_that("fails when lookback is not numeric", {
  expect_error(
    calculate_baseline(8, test_n, "invalid", test_lookahead),
    "^Argument 'lookback' must be single numeric value, received: invalid$"
  )
})

test_that("fails when lookback is not single value", {
  expect_error(
    calculate_baseline(8, test_n, c(2, 4), test_lookahead),
    "^Argument 'lookback' must be single numeric value, received: 2, 4$"
  )
})

test_that("fails when lookback is less than 1", {
  expect_error(
    calculate_baseline(8, test_n, 0, test_lookahead),
    "^Argument 'lookback' must be positive integer, received: 0$"
  )
})

test_that("fails when lookahead is not numeric", {
  expect_error(
    calculate_baseline(8, test_n, test_lookback, "invalid"),
    "^Argument 'lookahead' must be single numeric value, received: invalid$"
  )
})

test_that("fails when lookahead is not single value", {
  expect_error(
    calculate_baseline(8, test_n, test_lookback, c(3, 5)),
    "^Argument 'lookahead' must be single numeric value, received: 3, 5$"
  )
})

test_that("fails when lookahead is less than 1", {
  expect_error(
    calculate_baseline(8, test_n, test_lookback, 0),
    "^Argument 'lookahead' must be positive integer, received: 0$"
  )
})

test_that("converts numeric parameters to integers", {
  actual <- calculate_baseline(8.0, 15.0, 4.0, 4.0)
  expected <- c(4, 5, 6, 10, 11, 12)
  
  expect_equal(actual, expected)
})

test_that("handles boundary conditions correctly", {
  actual <- calculate_baseline(1, 3, lookback = 1, lookahead = 1)
  expected <- integer(0)
  
  expect_equal(actual, expected)
})

test_that("returns integer vector", {
  actual <- calculate_baseline(8, test_n, test_lookback, test_lookahead)
  
  expect_type(actual, "integer")
})