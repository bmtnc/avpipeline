test_that("validate_positive succeeds with positive numbers", {
  expect_null(validate_positive(1))
  expect_null(validate_positive(0.001))
  expect_null(validate_positive(1000))
})

test_that("validate_positive rejects zero", {
  expect_error(validate_positive(0), "must be greater than 0")
})

test_that("validate_positive rejects negative numbers", {
  expect_error(validate_positive(-1), "must be greater than 0")
  expect_error(validate_positive(-0.001), "must be greater than 0")
})

test_that("validate_positive rejects non-numeric types", {
  expect_error(validate_positive("5"), "must be a numeric scalar")
})

test_that("validate_positive uses custom name in error messages", {
  expect_error(
    validate_positive(-1, name = "threshold"),
    "threshold must be greater than 0"
  )
})
