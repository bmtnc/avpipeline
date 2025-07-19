
test_that("generates monthly dates for single year", {
  start_date <- as.Date("2020-01-31")
  end_date <- as.Date("2020-12-31")
  
  actual <- generate_month_end_dates(start_date, end_date)
  
  expected <- c(
    as.Date("2020-01-31"),
    as.Date("2020-02-29"),  # leap year
    as.Date("2020-03-31"),
    as.Date("2020-04-30"),
    as.Date("2020-05-31"),
    as.Date("2020-06-30"),
    as.Date("2020-07-31"),
    as.Date("2020-08-31"),
    as.Date("2020-09-30"),
    as.Date("2020-10-31"),
    as.Date("2020-11-30"),
    as.Date("2020-12-31")
  )
  
  expect_equal(actual, expected)
})

test_that("generates monthly dates for multiple years", {
  start_date <- as.Date("2019-11-30")
  end_date <- as.Date("2020-03-31")
  
  actual <- generate_month_end_dates(start_date, end_date)
  
  expected <- c(
    as.Date("2019-11-30"),
    as.Date("2019-12-31"),
    as.Date("2020-01-31"),
    as.Date("2020-02-29"),
    as.Date("2020-03-31")
  )
  
  expect_equal(actual, expected)
})

test_that("generates single month when start equals end", {
  start_date <- as.Date("2020-06-30")
  end_date <- as.Date("2020-06-30")
  
  actual <- generate_month_end_dates(start_date, end_date)
  
  expected <- as.Date("2020-06-30")
  
  expect_equal(actual, expected)
})

test_that("handles leap year February correctly", {
  start_date <- as.Date("2020-01-31")
  end_date <- as.Date("2020-03-31")
  
  actual <- generate_month_end_dates(start_date, end_date)
  
  expected <- c(
    as.Date("2020-01-31"),
    as.Date("2020-02-29"),  # leap year
    as.Date("2020-03-31")
  )
  
  expect_equal(actual, expected)
})

test_that("handles non-leap year February correctly", {
  start_date <- as.Date("2021-01-31")
  end_date <- as.Date("2021-03-31")
  
  actual <- generate_month_end_dates(start_date, end_date)
  
  expected <- c(
    as.Date("2021-01-31"),
    as.Date("2021-02-28"),  # non-leap year
    as.Date("2021-03-31")
  )
  
  expect_equal(actual, expected)
})

test_that("handles different month lengths correctly", {
  start_date <- as.Date("2020-01-31")
  end_date <- as.Date("2020-05-31")
  
  actual <- generate_month_end_dates(start_date, end_date)
  
  expected <- c(
    as.Date("2020-01-31"),  # 31 days
    as.Date("2020-02-29"),  # 29 days (leap)
    as.Date("2020-03-31"),  # 31 days
    as.Date("2020-04-30"),  # 30 days
    as.Date("2020-05-31")   # 31 days
  )
  
  expect_equal(actual, expected)
})

test_that("generates monthly dates starting from February", {
  start_date <- as.Date("2020-02-29")
  end_date <- as.Date("2020-05-31")
  
  actual <- generate_month_end_dates(start_date, end_date)
  
  expected <- c(
    as.Date("2020-02-29"),
    as.Date("2020-03-31"),
    as.Date("2020-04-30"),
    as.Date("2020-05-31")
  )
  
  expect_equal(actual, expected)
})

test_that("generates monthly dates across year boundary", {
  start_date <- as.Date("2020-10-31")
  end_date <- as.Date("2021-02-28")
  
  actual <- generate_month_end_dates(start_date, end_date)
  
  expected <- c(
    as.Date("2020-10-31"),
    as.Date("2020-11-30"),
    as.Date("2020-12-31"),
    as.Date("2021-01-31"),
    as.Date("2021-02-28")
  )
  
  expect_equal(actual, expected)
})

test_that("fails when start_date is greater than end_date", {
  expect_error(
    generate_month_end_dates(as.Date("2020-12-31"), as.Date("2020-01-31")),
    "^Input 'start_date' \\(2020-12-31\\) must be less than or equal to 'end_date' \\(2020-01-31\\)$"
  )
})

test_that("fails when start_date is not month-end date", {
  expect_error(
    generate_month_end_dates(as.Date("2020-01-30"), as.Date("2020-03-31")),
    "^Input 'start_date' \\(2020-01-30\\) must be a month-end date\\. Expected: 2020-01-31$"
  )
})

test_that("fails when end_date is not month-end date", {
  expect_error(
    generate_month_end_dates(as.Date("2020-01-31"), as.Date("2020-03-30")),
    "^Input 'end_date' \\(2020-03-30\\) must be a month-end date\\. Expected: 2020-03-31$"
  )
})