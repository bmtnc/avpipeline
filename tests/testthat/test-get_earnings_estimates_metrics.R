test_that("get_earnings_estimates_metrics returns expected columns", {
  metrics <- get_earnings_estimates_metrics()

  expect_type(metrics, "character")
  expect_equal(length(metrics), 16)

  expect_true("eps_estimate_average" %in% metrics)
  expect_true("eps_estimate_high" %in% metrics)
  expect_true("eps_estimate_low" %in% metrics)
  expect_true("eps_estimate_analyst_count" %in% metrics)
  expect_true("eps_estimate_average_7_days_ago" %in% metrics)
  expect_true("eps_estimate_average_30_days_ago" %in% metrics)
  expect_true("eps_estimate_average_60_days_ago" %in% metrics)
  expect_true("eps_estimate_average_90_days_ago" %in% metrics)
  expect_true("eps_estimate_revision_up_trailing_7_days" %in% metrics)
  expect_true("eps_estimate_revision_down_trailing_7_days" %in% metrics)
  expect_true("eps_estimate_revision_up_trailing_30_days" %in% metrics)
  expect_true("eps_estimate_revision_down_trailing_30_days" %in% metrics)
  expect_true("revenue_estimate_average" %in% metrics)
  expect_true("revenue_estimate_high" %in% metrics)
  expect_true("revenue_estimate_low" %in% metrics)
  expect_true("revenue_estimate_analyst_count" %in% metrics)
})

test_that("get_earnings_estimates_metrics returns no duplicates", {
  metrics <- get_earnings_estimates_metrics()
  expect_equal(length(metrics), length(unique(metrics)))
})
