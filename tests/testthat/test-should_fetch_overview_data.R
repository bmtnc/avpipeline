test_that("should_fetch_overview_data returns TRUE for NA timestamp", {
  result <- should_fetch_overview_data(
    overview_last_fetched_at = NA,
    reference_date = as.Date("2024-12-16")
  )
  expect_true(result)
})

test_that("should_fetch_overview_data returns TRUE when >90 days stale", {
  result <- should_fetch_overview_data(
    overview_last_fetched_at = as.POSIXct("2024-06-01 10:00:00"),
    reference_date = as.Date("2024-12-16")
  )
  expect_true(result)
})

test_that("should_fetch_overview_data returns FALSE when recent", {
  result <- should_fetch_overview_data(
    overview_last_fetched_at = as.POSIXct("2024-12-01 10:00:00"),
    reference_date = as.Date("2024-12-16")
  )
  expect_false(result)
})

test_that("should_fetch_overview_data validates reference_date", {
  expect_error(
    should_fetch_overview_data(NA, "not-a-date"),
    "reference_date"
  )
})
