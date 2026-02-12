test_that("derive_weekly_dates returns last trading day per week", {
  # 3 weeks of daily data (Mon-Fri, skipping weekends)
  price_data <- tibble::tibble(
    date = as.Date(c(
      # Week 1: Jan 6-10
      "2025-01-06", "2025-01-07", "2025-01-08", "2025-01-09", "2025-01-10",
      # Week 2: Jan 13-17
      "2025-01-13", "2025-01-14", "2025-01-15", "2025-01-16", "2025-01-17",
      # Week 3: Jan 20-24
      "2025-01-20", "2025-01-21", "2025-01-22", "2025-01-23", "2025-01-24"
    ))
  )

  result <- derive_weekly_dates(price_data, n_weeks = 52)

  expect_length(result, 3)
  expect_s3_class(result, "Date")
  # Most recent first

  expect_equal(result[1], as.Date("2025-01-24"))
  expect_equal(result[2], as.Date("2025-01-17"))
  expect_equal(result[3], as.Date("2025-01-10"))
})

test_that("derive_weekly_dates respects n_weeks limit", {
  price_data <- tibble::tibble(
    date = as.Date(c(
      "2025-01-06", "2025-01-10",
      "2025-01-13", "2025-01-17",
      "2025-01-20", "2025-01-24"
    ))
  )

  result <- derive_weekly_dates(price_data, n_weeks = 2)

  expect_length(result, 2)
  expect_equal(result[1], as.Date("2025-01-24"))
  expect_equal(result[2], as.Date("2025-01-17"))
})

test_that("derive_weekly_dates handles holidays (short week)", {
  # Week with Monday holiday — last trading day is Thursday
  price_data <- tibble::tibble(
    date = as.Date(c(
      "2025-01-07", "2025-01-08", "2025-01-09", "2025-01-10",
      "2025-01-13", "2025-01-14", "2025-01-15", "2025-01-16", "2025-01-17"
    ))
  )

  result <- derive_weekly_dates(price_data, n_weeks = 52)

  expect_length(result, 2)
  expect_equal(result[1], as.Date("2025-01-17"))
  expect_equal(result[2], as.Date("2025-01-10"))
})

test_that("derive_weekly_dates returns empty for empty input", {
  price_data <- tibble::tibble(date = as.Date(character()))

  result <- derive_weekly_dates(price_data, n_weeks = 10)

  expect_length(result, 0)
  expect_s3_class(result, "Date")
})

test_that("derive_weekly_dates errors on missing date column", {
  price_data <- tibble::tibble(price = c(100, 101, 102))

  expect_error(derive_weekly_dates(price_data), "date")
})

test_that("derive_weekly_dates errors on invalid n_weeks", {
  price_data <- tibble::tibble(date = as.Date("2025-01-10"))

  expect_error(derive_weekly_dates(price_data, n_weeks = 0), "positive integer")
  expect_error(derive_weekly_dates(price_data, n_weeks = -1), "positive integer")
})

test_that("derive_weekly_dates handles fewer weeks than requested", {
  price_data <- tibble::tibble(
    date = as.Date(c("2025-01-06", "2025-01-07", "2025-01-08"))
  )

  result <- derive_weekly_dates(price_data, n_weeks = 100)

  expect_length(result, 1)
  expect_equal(result[1], as.Date("2025-01-08"))
})
