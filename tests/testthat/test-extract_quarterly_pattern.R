# Test data setup
monthly_dates_2020_2022 <- generate_month_end_dates(as.Date("2020-01-31"), as.Date("2022-12-31"))

test_that("extracts standard quarterly pattern from February start", {
  first_date <- as.Date("2020-02-29")
  last_date <- as.Date("2021-02-28")
  
  actual <- extract_quarterly_pattern(first_date, last_date, monthly_dates_2020_2022)
  
  expected <- c(
    as.Date("2020-02-29"),
    as.Date("2020-05-31"),
    as.Date("2020-08-31"),
    as.Date("2020-11-30"),
    as.Date("2021-02-28")
  )
  
  expect_equal(actual, expected)
})

test_that("extracts quarterly pattern from January 31 handling month-end variations", {
  first_date <- as.Date("2020-01-31")
  last_date <- as.Date("2020-10-31")
  
  actual <- extract_quarterly_pattern(first_date, last_date, monthly_dates_2020_2022)
  
  expected <- c(
    as.Date("2020-01-31"),
    as.Date("2020-04-30"),  # April has only 30 days
    as.Date("2020-07-31"),
    as.Date("2020-10-31")
  )
  
  expect_equal(actual, expected)
})

test_that("handles leap year transitions correctly", {
  first_date <- as.Date("2020-02-29")  # Leap year
  last_date <- as.Date("2022-02-28")   # Non-leap year
  
  actual <- extract_quarterly_pattern(first_date, last_date, monthly_dates_2020_2022)
  
  expected <- c(
    as.Date("2020-02-29"),
    as.Date("2020-05-31"),
    as.Date("2020-08-31"),
    as.Date("2020-11-30"),
    as.Date("2021-02-28"),  # Non-leap year February
    as.Date("2021-05-31"),
    as.Date("2021-08-31"),
    as.Date("2021-11-30"),
    as.Date("2022-02-28")   # Non-leap year February
  )
  
  expect_equal(actual, expected)
})

test_that("extracts quarterly pattern from calendar quarter-end dates", {
  first_date <- as.Date("2020-03-31")
  last_date <- as.Date("2020-12-31")
  
  actual <- extract_quarterly_pattern(first_date, last_date, monthly_dates_2020_2022)
  
  expected <- c(
    as.Date("2020-03-31"),
    as.Date("2020-06-30"),
    as.Date("2020-09-30"),
    as.Date("2020-12-31")
  )
  
  expect_equal(actual, expected)
})

test_that("returns single date when first_date equals last_date", {
  first_date <- as.Date("2020-06-30")
  last_date <- as.Date("2020-06-30")
  
  actual <- extract_quarterly_pattern(first_date, last_date, monthly_dates_2020_2022)
  
  expected <- as.Date("2020-06-30")
  
  expect_equal(actual, expected)
})

test_that("stops before last_date when last_date falls between quarters", {
  first_date <- as.Date("2020-01-31")
  last_date <- as.Date("2020-06-15")  # Between Apr 30 and Jul 31
  
  actual <- extract_quarterly_pattern(first_date, last_date, monthly_dates_2020_2022)
  
  expected <- c(
    as.Date("2020-01-31"),
    as.Date("2020-04-30")
  )
  
  expect_equal(actual, expected)
})

test_that("handles fiscal year ending in November", {
  first_date <- as.Date("2020-11-30")
  last_date <- as.Date("2021-08-31")
  
  actual <- extract_quarterly_pattern(first_date, last_date, monthly_dates_2020_2022)
  
  expected <- c(
    as.Date("2020-11-30"),
    as.Date("2021-02-28"),  # Feb has 28 days in 2021
    as.Date("2021-05-31"),
    as.Date("2021-08-31")
  )
  
  expect_equal(actual, expected)
})

test_that("handles quarterly pattern near end of monthly sequence", {
  first_date <- as.Date("2022-09-30")
  last_date <- as.Date("2022-12-31")
  
  actual <- extract_quarterly_pattern(first_date, last_date, monthly_dates_2020_2022)
  
  expected <- c(
    as.Date("2022-09-30"),
    as.Date("2022-12-31")
  )
  
  expect_equal(actual, expected)
})

test_that("returns empty when first_date is last in sequence and exceeds last_date", {
  first_date <- as.Date("2022-12-31")
  last_date <- as.Date("2022-11-30")  # Before first_date
  
  expect_error(
    extract_quarterly_pattern(first_date, last_date, monthly_dates_2020_2022),
    "^Input 'first_date' \\(2022-12-31\\) must be less than or equal to 'last_date' \\(2022-11-30\\)$"
  )
})

test_that("handles June 30 fiscal year pattern", {
  first_date <- as.Date("2020-06-30")
  last_date <- as.Date("2021-03-31")
  
  actual <- extract_quarterly_pattern(first_date, last_date, monthly_dates_2020_2022)
  
  expected <- c(
    as.Date("2020-06-30"),
    as.Date("2020-09-30"),
    as.Date("2020-12-31"),
    as.Date("2021-03-31")
  )
  
  expect_equal(actual, expected)
})

test_that("handles quarterly pattern across multiple years", {
  first_date <- as.Date("2020-01-31")
  last_date <- as.Date("2022-01-31")
  
  actual <- extract_quarterly_pattern(first_date, last_date, monthly_dates_2020_2022)
  
  expected <- c(
    as.Date("2020-01-31"),
    as.Date("2020-04-30"),
    as.Date("2020-07-31"),
    as.Date("2020-10-31"),
    as.Date("2021-01-31"),
    as.Date("2021-04-30"),
    as.Date("2021-07-31"),
    as.Date("2021-10-31"),
    as.Date("2022-01-31")
  )
  
  expect_equal(actual, expected)
})

test_that("fails when first_date is not Date object", {
  expect_error(
    extract_quarterly_pattern("2020-01-31", as.Date("2020-12-31"), monthly_dates_2020_2022),
    "^first_date must be a Date object\\. Received: character$"
  )
})

test_that("fails when last_date is not Date object", {
  expect_error(
    extract_quarterly_pattern(as.Date("2020-01-31"), "2020-12-31", monthly_dates_2020_2022),
    "^last_date must be a Date object\\. Received: character$"
  )
})

test_that("fails when monthly_dates is not Date vector", {
  expect_error(
    extract_quarterly_pattern(as.Date("2020-01-31"), as.Date("2020-12-31"), c("2020-01-31", "2020-02-29")),
    "^monthly_dates must be a Date object\\. Received: character$"
  )
})

test_that("fails when first_date has multiple values", {
  expect_error(
    extract_quarterly_pattern(c(as.Date("2020-01-31"), as.Date("2020-02-29")), as.Date("2020-12-31"), monthly_dates_2020_2022),
    "^first_date must be a Date scalar \\(length 1\\)\\. Received length: 2$"
  )
})

test_that("fails when last_date has multiple values", {
  expect_error(
    extract_quarterly_pattern(as.Date("2020-01-31"), c(as.Date("2020-12-31"), as.Date("2021-01-31")), monthly_dates_2020_2022),
    "^last_date must be a Date scalar \\(length 1\\)\\. Received length: 2$"
  )
})

test_that("fails when monthly_dates is empty", {
  expect_error(
    extract_quarterly_pattern(as.Date("2020-01-31"), as.Date("2020-12-31"), as.Date(character(0))),
    "^monthly_dates must not be empty \\(length 0\\)$"
  )
})

test_that("fails when first_date is greater than last_date", {
  expect_error(
    extract_quarterly_pattern(as.Date("2020-12-31"), as.Date("2020-01-31"), monthly_dates_2020_2022),
    "^Input 'first_date' \\(2020-12-31\\) must be less than or equal to 'last_date' \\(2020-01-31\\)$"
  )
})

test_that("fails when first_date is not in monthly_dates sequence", {
  expect_error(
    extract_quarterly_pattern(as.Date("2020-01-15"), as.Date("2020-12-31"), monthly_dates_2020_2022),
    "^Input 'first_date' \\(2020-01-15\\) must be present in 'monthly_dates' sequence$"
  )
})

test_that("fails when first_date is outside monthly_dates range", {
  expect_error(
    extract_quarterly_pattern(as.Date("2019-12-31"), as.Date("2020-12-31"), monthly_dates_2020_2022),
    "^Input 'first_date' \\(2019-12-31\\) must be present in 'monthly_dates' sequence$"
  )
})