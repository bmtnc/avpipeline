test_that("validate_numeric_scalar succeeds with valid numeric", {
  expect_null(validate_numeric_scalar(42))
  expect_null(validate_numeric_scalar(-5.5))
  expect_null(validate_numeric_scalar(0))
})

test_that("validate_numeric_scalar rejects non-numeric types", {
  expect_error(
    validate_numeric_scalar("123"),
    "Input must be a numeric scalar.*Received: character"
  )
  expect_error(
    validate_numeric_scalar(TRUE),
    "Input must be a numeric scalar.*Received: logical"
  )
})

test_that("validate_numeric_scalar rejects vectors of length != 1", {
  expect_error(
    validate_numeric_scalar(c(1, 2)),
    "Input must be a numeric scalar.*length 2"
  )
  expect_error(
    validate_numeric_scalar(numeric(0)),
    "Input must be a numeric scalar.*length 0"
  )
})

test_that("validate_numeric_scalar rejects NA", {
  expect_error(validate_numeric_scalar(NA_real_), "must not be NA")
})

test_that("validate_numeric_scalar enforces gt bound", {
  expect_null(validate_numeric_scalar(5, gt = 0))
  expect_error(validate_numeric_scalar(0, gt = 0), "must be greater than 0")
  expect_error(validate_numeric_scalar(-1, gt = 0), "must be greater than 0")
})

test_that("validate_numeric_scalar enforces gte bound", {
  expect_null(validate_numeric_scalar(0, gte = 0))
  expect_null(validate_numeric_scalar(5, gte = 0))
  expect_error(validate_numeric_scalar(-1, gte = 0), "must be >= 0")
})

test_that("validate_numeric_scalar enforces lt bound", {
  expect_null(validate_numeric_scalar(0, lt = 1))
  expect_error(validate_numeric_scalar(1, lt = 1), "must be less than 1")
  expect_error(validate_numeric_scalar(2, lt = 1), "must be less than 1")
})

test_that("validate_numeric_scalar enforces lte bound", {
  expect_null(validate_numeric_scalar(1, lte = 1))
  expect_null(validate_numeric_scalar(0, lte = 1))
  expect_error(validate_numeric_scalar(2, lte = 1), "must be <= 1")
})

test_that("validate_numeric_scalar uses custom name in error messages", {
  expect_error(
    validate_numeric_scalar("x", name = "threshold"),
    "threshold must be a numeric scalar"
  )
})
