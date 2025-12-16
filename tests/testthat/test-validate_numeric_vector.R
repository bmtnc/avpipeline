test_that("validate_numeric_vector succeeds with valid vectors", {
  expect_null(validate_numeric_vector(c(1, 2, 3)))
  expect_null(validate_numeric_vector(1))  # single value is valid
  expect_null(validate_numeric_vector(c(1.5, 2.5)))
})

test_that("validate_numeric_vector rejects non-numeric types", {
  expect_error(
    validate_numeric_vector("123"),
    "must be a numeric vector.*Received: character"
  )
  expect_error(
    validate_numeric_vector(c(TRUE, FALSE)),
    "must be a numeric vector.*Received: logical"
  )
  expect_error(
    validate_numeric_vector(list(1, 2)),
    "must be a numeric vector.*Received: list"
  )
})

test_that("validate_numeric_vector enforces non-empty by default", {
  expect_error(
    validate_numeric_vector(numeric(0)),
    "must not be empty"
  )
})

test_that("validate_numeric_vector allows empty when allow_empty = TRUE", {
  expect_null(validate_numeric_vector(numeric(0), allow_empty = TRUE))
})

test_that("validate_numeric_vector uses custom name in error messages", {
  expect_error(
    validate_numeric_vector("x", name = "values"),
    "values must be a numeric vector"
  )
})
