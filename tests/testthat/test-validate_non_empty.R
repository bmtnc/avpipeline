test_that("validate_non_empty succeeds with non-empty objects", {
  expect_null(validate_non_empty(c(1, 2, 3)))
  expect_null(validate_non_empty("test"))
  expect_null(validate_non_empty(list(a = 1)))
  expect_null(validate_non_empty(data.frame(a = 1)))
})

test_that("validate_non_empty errors on NULL", {
  expect_error(validate_non_empty(NULL), "must not be NULL")
})

test_that("validate_non_empty errors on empty vectors", {
  expect_error(validate_non_empty(character(0)), "must not be empty")
  expect_error(validate_non_empty(numeric(0)), "must not be empty")
  expect_error(validate_non_empty(list()), "must not be empty")
})

test_that("validate_non_empty errors on empty data.frame", {
  expect_error(
    validate_non_empty(data.frame()),
    "must have at least one row"
  )
  expect_error(
    validate_non_empty(data.frame(a = numeric(0))),
    "must have at least one row"
  )
})

test_that("validate_non_empty uses custom name in error messages", {
  expect_error(
    validate_non_empty(NULL, name = "ticker_data"),
    "ticker_data must not be NULL"
  )
})
