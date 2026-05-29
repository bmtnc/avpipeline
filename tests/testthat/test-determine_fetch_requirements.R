ref <- as.Date("2026-05-28")

tracking <- function(last_fetched_days_ago = 20, next_report_in_days = 40) {
  tibble::tibble(
    ticker = "AAPL",
    next_estimated_report_date = if (is.na(next_report_in_days)) {
      as.Date(NA)
    } else {
      ref + next_report_in_days
    },
    quarterly_last_fetched_at = if (is.na(last_fetched_days_ago)) {
      as.POSIXct(NA)
    } else {
      as.POSIXct(ref - last_fetched_days_ago)
    }
  )
}

test_that("price_only fetches only price, regardless of tracking", {
  out <- determine_fetch_requirements(tracking(), ref, "price_only")
  expect_equal(out, list(price = TRUE, splits = FALSE, quarterly = FALSE))
})

test_that("quarterly_only skips a ticker that is fresh and far from earnings", {
  out <- determine_fetch_requirements(
    tracking(last_fetched_days_ago = 20, next_report_in_days = 40), ref, "quarterly_only"
  )
  expect_equal(out, list(price = FALSE, splits = FALSE, quarterly = FALSE))
})

test_that("quarterly_only fetches a ticker inside the earnings window", {
  out <- determine_fetch_requirements(
    tracking(last_fetched_days_ago = 20, next_report_in_days = 2), ref, "quarterly_only"
  )
  expect_true(out$quarterly)
  expect_false(out$price)
  expect_false(out$splits)
})

test_that("quarterly_only fetches a stale ticker (>90 days)", {
  out <- determine_fetch_requirements(
    tracking(last_fetched_days_ago = 100, next_report_in_days = 40), ref, "quarterly_only"
  )
  expect_true(out$quarterly)
})

test_that("quarterly_only fetches a brand-new ticker (no prior fetch)", {
  out <- determine_fetch_requirements(
    tracking(last_fetched_days_ago = NA, next_report_in_days = NA), ref, "quarterly_only"
  )
  expect_true(out$quarterly)
})

test_that("full always fetches price and splits, quarterly is smart-gated", {
  not_due <- determine_fetch_requirements(
    tracking(last_fetched_days_ago = 20, next_report_in_days = 40), ref, "full"
  )
  expect_equal(not_due, list(price = TRUE, splits = TRUE, quarterly = FALSE))

  due <- determine_fetch_requirements(
    tracking(last_fetched_days_ago = 20, next_report_in_days = 2), ref, "full"
  )
  expect_equal(due, list(price = TRUE, splits = TRUE, quarterly = TRUE))
})

test_that("invalid fetch_mode errors", {
  expect_error(
    determine_fetch_requirements(tracking(), ref, "bogus"),
    "fetch_mode"
  )
})
