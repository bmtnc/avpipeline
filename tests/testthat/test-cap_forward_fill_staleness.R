make_filled_daily <- function(dates, reported, revenue_ttm) {
  tibble::tibble(
    ticker = "A",
    date = as.Date(dates),
    adjusted_close = 100,
    reportedDate = as.Date(reported),
    fiscalDateEnding = as.Date(reported) - 30,
    totalRevenue_ttm = revenue_ttm
  )
}

financial_cols <- c("reportedDate", "fiscalDateEnding", "totalRevenue_ttm")

test_that("rows within the fill horizon are unchanged", {
  data <- make_filled_daily(
    dates = c("2026-08-01", "2026-08-02"),
    reported = "2026-07-30",
    revenue_ttm = 500
  )

  result <- cap_forward_fill_staleness(data, financial_cols)

  expect_equal(result, data)
})

test_that("financial columns go NA beyond the fill horizon, prices untouched", {
  data <- make_filled_daily(
    dates = c("2022-09-01", "2026-08-01"),
    reported = "2022-08-15",
    revenue_ttm = 500
  )

  result <- cap_forward_fill_staleness(data, financial_cols)

  expect_equal(result$totalRevenue_ttm, c(500, NA))
  expect_equal(result$reportedDate, as.Date(c("2022-08-15", NA)))
  expect_equal(result$fiscalDateEnding[2], as.Date(NA))
  expect_equal(result$adjusted_close, c(100, 100))
  expect_equal(result$date, as.Date(c("2022-09-01", "2026-08-01")))
})

test_that("rows with NA reportedDate are left as-is", {
  data <- make_filled_daily(
    dates = "2026-08-01",
    reported = NA,
    revenue_ttm = NA
  )

  result <- cap_forward_fill_staleness(data, financial_cols)

  expect_equal(result, data)
})

test_that("custom max_fill_days is respected", {
  data <- make_filled_daily(
    dates = c("2026-08-05", "2026-08-15"),
    reported = "2026-08-01",
    revenue_ttm = 500
  )

  result <- cap_forward_fill_staleness(data, financial_cols, max_fill_days = 10)

  expect_equal(result$totalRevenue_ttm, c(500, NA))
})

test_that("financial columns absent from data are ignored", {
  data <- make_filled_daily(
    dates = "2026-08-01",
    reported = "2026-07-30",
    revenue_ttm = 500
  )

  result <- cap_forward_fill_staleness(
    data,
    c(financial_cols, "not_a_column")
  )

  expect_equal(result, data)
})
