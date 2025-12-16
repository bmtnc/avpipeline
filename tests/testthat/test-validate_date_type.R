test_that("validate_date_type succeeds with valid Date", {
  expect_null(validate_date_type(as.Date("2024-01-01")))
  expect_null(validate_date_type(Sys.Date()))
})

test_that("validate_date_type rejects non-Date types", {
  expect_error(
    validate_date_type("2024-01-01"),
    "must be a Date object.*Received: character"
  )
  expect_error(
    validate_date_type(20240101),
    "must be a Date object.*Received: numeric"
  )
  expect_error(
    validate_date_type(as.POSIXct("2024-01-01")),
    "must be a Date object.*Received: POSIXct"
  )
})

test_that("validate_date_type enforces scalar by default", {
  expect_error(
    validate_date_type(as.Date(c("2024-01-01", "2024-02-01"))),
    "must be a Date scalar.*Received length: 2"
  )
})

test_that("validate_date_type allows vectors when scalar = FALSE", {
  expect_null(validate_date_type(as.Date(c("2024-01-01", "2024-02-01")), scalar = FALSE))
})

test_that("validate_date_type uses custom name in error messages", {
  expect_error(
    validate_date_type("2024-01-01", name = "start_date"),
    "start_date must be a Date object"
  )
})
