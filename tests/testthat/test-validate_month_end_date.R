
test_that("validates January 31 month end", {
  expect_silent(validate_month_end_date(as.Date("2020-01-31"), "test_date"))
})

test_that("validates February 29 month end in leap year", {
  expect_silent(validate_month_end_date(as.Date("2020-02-29"), "test_date"))
})

test_that("validates February 28 month end in non-leap year", {
  expect_silent(validate_month_end_date(as.Date("2021-02-28"), "test_date"))
})

test_that("validates March 31 month end", {
  expect_silent(validate_month_end_date(as.Date("2020-03-31"), "test_date"))
})

test_that("validates April 30 month end", {
  expect_silent(validate_month_end_date(as.Date("2020-04-30"), "test_date"))
})

test_that("validates May 31 month end", {
  expect_silent(validate_month_end_date(as.Date("2020-05-31"), "test_date"))
})

test_that("validates June 30 month end", {
  expect_silent(validate_month_end_date(as.Date("2020-06-30"), "test_date"))
})

test_that("validates December 31 month end", {
  expect_silent(validate_month_end_date(as.Date("2020-12-31"), "test_date"))
})

test_that("validates month ends across different years", {
  expect_silent(validate_month_end_date(as.Date("2019-01-31"), "test_date"))
  expect_silent(validate_month_end_date(as.Date("2021-06-30"), "test_date"))
  expect_silent(validate_month_end_date(as.Date("2022-09-30"), "test_date"))
  expect_silent(validate_month_end_date(as.Date("2023-12-31"), "test_date"))
})

test_that("fails when date is not Date object", {
  expect_error(
    validate_month_end_date("2020-01-31", "test_date"),
    "^Input 'test_date' must be a Date object\\. Received: character$"
  )
})

test_that("fails when date is numeric", {
  expect_error(
    validate_month_end_date(20200131, "test_date"),
    "^Input 'test_date' must be a Date object\\. Received: numeric$"
  )
})

test_that("fails when date has multiple values", {
  expect_error(
    validate_month_end_date(c(as.Date("2020-01-31"), as.Date("2020-02-29")), "test_date"),
    "^Input 'test_date' must be a single Date value\\. Received length: 2$"
  )
})

test_that("fails when date is January 30", {
  expect_error(
    validate_month_end_date(as.Date("2020-01-30"), "test_date"),
    "^Input 'test_date' \\(2020-01-30\\) must be a month-end date\\. Expected: 2020-01-31$"
  )
})

test_that("fails when date is February 28 in leap year", {
  expect_error(
    validate_month_end_date(as.Date("2020-02-28"), "test_date"),
    "^Input 'test_date' \\(2020-02-28\\) must be a month-end date\\. Expected: 2020-02-29$"
  )
})

test_that("fails when date is February 27 in non-leap year", {
  expect_error(
    validate_month_end_date(as.Date("2021-02-27"), "test_date"),
    "^Input 'test_date' \\(2021-02-27\\) must be a month-end date\\. Expected: 2021-02-28$"
  )
})

test_that("fails when date is April 29", {
  expect_error(
    validate_month_end_date(as.Date("2020-04-29"), "test_date"),
    "^Input 'test_date' \\(2020-04-29\\) must be a month-end date\\. Expected: 2020-04-30$"
  )
})

test_that("fails when date is June 29", {
  expect_error(
    validate_month_end_date(as.Date("2020-06-29"), "test_date"),
    "^Input 'test_date' \\(2020-06-29\\) must be a month-end date\\. Expected: 2020-06-30$"
  )
})

test_that("fails when date is December 30", {
  expect_error(
    validate_month_end_date(as.Date("2020-12-30"), "test_date"),
    "^Input 'test_date' \\(2020-12-30\\) must be a month-end date\\. Expected: 2020-12-31$"
  )
})

test_that("fails when date is first day of month", {
  expect_error(
    validate_month_end_date(as.Date("2020-05-01"), "test_date"),
    "^Input 'test_date' \\(2020-05-01\\) must be a month-end date\\. Expected: 2020-05-31$"
  )
})

test_that("fails when date is mid-month", {
  expect_error(
    validate_month_end_date(as.Date("2020-07-15"), "test_date"),
    "^Input 'test_date' \\(2020-07-15\\) must be a month-end date\\. Expected: 2020-07-31$"
  )
})

test_that("uses custom parameter name in error messages", {
  expect_error(
    validate_month_end_date(as.Date("2020-05-15"), "custom_param"),
    "^Input 'custom_param' \\(2020-05-15\\) must be a month-end date\\. Expected: 2020-05-31$"
  )
})