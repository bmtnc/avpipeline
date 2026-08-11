test_that("should_fetch_quarterly_data returns TRUE for new ticker (NA fetch time)", {
  expect_true(should_fetch_quarterly_data(
    next_estimated_report_date = as.Date("2024-12-20"),
    quarterly_last_fetched_at = NA,
    reference_date = as.Date("2024-12-15")
  ))
})

test_that("should_fetch_quarterly_data returns TRUE when data is stale (>90 days)", {
  expect_true(should_fetch_quarterly_data(
    next_estimated_report_date = as.Date("2025-03-01"),
    quarterly_last_fetched_at = as.POSIXct("2024-09-01"),
    reference_date = as.Date("2024-12-15")
  ))
})

test_that("should_fetch_quarterly_data returns TRUE within earnings window", {
  # 3 days before earnings
  expect_true(should_fetch_quarterly_data(
    next_estimated_report_date = as.Date("2024-12-18"),
    quarterly_last_fetched_at = as.POSIXct("2024-12-01"),
    reference_date = as.Date("2024-12-15")
  ))

  # 3 days after earnings
  expect_true(should_fetch_quarterly_data(
    next_estimated_report_date = as.Date("2024-12-12"),
    quarterly_last_fetched_at = as.POSIXct("2024-12-01"),
    reference_date = as.Date("2024-12-15")
  ))

  # Exactly on earnings date
  expect_true(should_fetch_quarterly_data(
    next_estimated_report_date = as.Date("2024-12-15"),
    quarterly_last_fetched_at = as.POSIXct("2024-12-01"),
    reference_date = as.Date("2024-12-15")
  ))
})

test_that("should_fetch_quarterly_data returns FALSE outside earnings window", {
  # 30 days before earnings, data is fresh
  expect_false(should_fetch_quarterly_data(
    next_estimated_report_date = as.Date("2025-01-15"),
    quarterly_last_fetched_at = as.POSIXct("2024-12-10"),
    reference_date = as.Date("2024-12-15")
  ))
})

test_that("should_fetch_quarterly_data returns FALSE with no prediction but fresh data", {
  expect_false(should_fetch_quarterly_data(
    next_estimated_report_date = NA,
    quarterly_last_fetched_at = as.POSIXct("2024-12-10"),
    reference_date = as.Date("2024-12-15")
  ))
})

test_that("should_fetch_quarterly_data retries while statements lag earnings", {
  # Outside earnings window, fresh fetch — would be FALSE without the lag flag
  expect_true(should_fetch_quarterly_data(
    next_estimated_report_date = as.Date("2026-10-25"),
    quarterly_last_fetched_at = as.POSIXct("2026-07-31"),
    reference_date = as.Date("2026-08-11"),
    statements_lag_earnings = TRUE,
    last_reported_date = as.Date("2026-07-30")
  ))
})

test_that("should_fetch_quarterly_data stops lag retries past the retry bound", {
  expect_false(should_fetch_quarterly_data(
    next_estimated_report_date = as.Date("2026-12-20"),
    quarterly_last_fetched_at = as.POSIXct("2026-09-20"),
    reference_date = as.Date("2026-09-25"),
    statements_lag_earnings = TRUE,
    last_reported_date = as.Date("2026-07-30")
  ))
})

test_that("should_fetch_quarterly_data ignores lag flag with NA reported date", {
  expect_false(should_fetch_quarterly_data(
    next_estimated_report_date = as.Date("2026-10-25"),
    quarterly_last_fetched_at = as.POSIXct("2026-07-31"),
    reference_date = as.Date("2026-08-11"),
    statements_lag_earnings = TRUE,
    last_reported_date = as.Date(NA)
  ))
})

test_that("should_fetch_quarterly_data unaffected by lag args when not lagged", {
  expect_false(should_fetch_quarterly_data(
    next_estimated_report_date = as.Date("2026-10-25"),
    quarterly_last_fetched_at = as.POSIXct("2026-07-31"),
    reference_date = as.Date("2026-08-11"),
    statements_lag_earnings = FALSE,
    last_reported_date = as.Date("2026-07-30")
  ))
})

test_that("should_fetch_quarterly_data respects custom window_days", {
  # 7 days before earnings, default window (5) would say no
  expect_false(should_fetch_quarterly_data(
    next_estimated_report_date = as.Date("2024-12-22"),
    quarterly_last_fetched_at = as.POSIXct("2024-12-10"),
    reference_date = as.Date("2024-12-15"),
    window_days = 5
  ))

  # Same scenario with larger window (10) would say yes
  expect_true(should_fetch_quarterly_data(
    next_estimated_report_date = as.Date("2024-12-22"),
    quarterly_last_fetched_at = as.POSIXct("2024-12-10"),
    reference_date = as.Date("2024-12-15"),
    window_days = 10
  ))
})

test_that("should_fetch_quarterly_data validates reference_date", {
  expect_error(
    should_fetch_quarterly_data(
      next_estimated_report_date = as.Date("2024-12-20"),
      quarterly_last_fetched_at = NA,
      reference_date = "2024-12-15"
    ),
    "reference_date"
  )
})

test_that("calculate_next_estimated_report_date predicts correctly", {
  result <- calculate_next_estimated_report_date(
    last_fiscal_date_ending = as.Date("2024-09-30"),
    last_reported_date = as.Date("2024-11-01"),
    median_report_delay_days = 40L
  )

  # Next quarter: 2024-09-30 + 91 = 2024-12-30
  # Plus delay: 2024-12-30 + 40 = 2025-02-08
  expect_equal(result, as.Date("2025-02-08"))
})

test_that("calculate_next_estimated_report_date uses default delay when NA", {
  result <- calculate_next_estimated_report_date(
    last_fiscal_date_ending = as.Date("2024-09-30"),
    last_reported_date = as.Date("2024-11-01"),
    median_report_delay_days = NA
  )

  # Next quarter: 2024-09-30 + 91 = 2024-12-30
  # Plus default delay (45): 2024-12-30 + 45 = 2025-02-13
  expect_equal(result, as.Date("2025-02-13"))
})

test_that("calculate_next_estimated_report_date returns NA for NA input", {
  result <- calculate_next_estimated_report_date(
    last_fiscal_date_ending = NA,
    last_reported_date = as.Date("2024-11-01"),
    median_report_delay_days = 40L
  )

  expect_true(is.na(result))
})

test_that("calculate_median_report_delay calculates correctly", {
  # nolint start
  # fmt: skip
  earnings_data <- tibble::tribble(
    ~fiscalDateEnding, ~reportedDate,
    "2024-03-31",      "2024-05-01",
    "2024-06-30",      "2024-08-01",
    "2024-09-30",      "2024-11-01"
  ) %>%
    dplyr::mutate(dplyr::across(c(fiscalDateEnding, reportedDate), as.Date))
  # nolint end
  # Delays: 31, 32, 32 -> median = 32

  result <- calculate_median_report_delay(earnings_data)

  expect_equal(result, 32L)
})
test_that("calculate_median_report_delay returns NA for empty data", {
  earnings_data <- tibble::tibble(
    fiscalDateEnding = as.Date(character()),
    reportedDate = as.Date(character())
  )

  result <- calculate_median_report_delay(earnings_data)

  expect_true(is.na(result))
})

test_that("calculate_median_report_delay returns NA for insufficient data", {
  # nolint start
  # fmt: skip
  earnings_data <- tibble::tribble(
    ~fiscalDateEnding, ~reportedDate,
    "2024-09-30",      "2024-11-01"
  ) %>%
    dplyr::mutate(dplyr::across(c(fiscalDateEnding, reportedDate), as.Date))
  # nolint end

  result <- calculate_median_report_delay(earnings_data)

  expect_true(is.na(result))
})

test_that("calculate_median_report_delay validates inputs", {
  expect_error(calculate_median_report_delay("not_a_df"), "data.frame")

  bad_df <- tibble::tibble(x = 1:3)
  expect_error(calculate_median_report_delay(bad_df), "fiscalDateEnding")
})

test_that("determine_fetch_requirements always fetches price and splits", {
  ticker_tracking <- create_default_ticker_tracking("AAPL")
  ticker_tracking$quarterly_last_fetched_at <- as.POSIXct("2024-12-10")
  ticker_tracking$next_estimated_report_date <- as.Date("2025-03-01")

  result <- determine_fetch_requirements(
    ticker_tracking,
    reference_date = as.Date("2024-12-15")
  )

  expect_true(result$price)
  expect_true(result$splits)
})

test_that("determine_fetch_requirements respects quarterly logic", {
  ticker_tracking <- create_default_ticker_tracking("AAPL")
  ticker_tracking$quarterly_last_fetched_at <- as.POSIXct("2024-12-10")

  # Far from earnings - don't fetch
  ticker_tracking$next_estimated_report_date <- as.Date("2025-03-01")
  result <- determine_fetch_requirements(
    ticker_tracking,
    reference_date = as.Date("2024-12-15")
  )
  expect_false(result$quarterly)

  # Near earnings - fetch
  ticker_tracking$next_estimated_report_date <- as.Date("2024-12-18")
  result <- determine_fetch_requirements(
    ticker_tracking,
    reference_date = as.Date("2024-12-15")
  )
  expect_true(result$quarterly)
})

test_that("determine_fetch_requirements fetches quarterly while statements lag", {
  tracking <- create_default_ticker_tracking("AMZN")
  tracking$quarterly_last_fetched_at <- as.POSIXct("2026-07-31")
  tracking$next_estimated_report_date <- as.Date("2026-10-25")
  tracking$last_reported_date <- as.Date("2026-07-30")
  tracking$has_data_discrepancy <- TRUE

  requirements <- determine_fetch_requirements(
    tracking,
    reference_date = as.Date("2026-08-11")
  )
  expect_true(requirements$quarterly)

  tracking$has_data_discrepancy <- FALSE
  requirements <- determine_fetch_requirements(
    tracking,
    reference_date = as.Date("2026-08-11")
  )
  expect_false(requirements$quarterly)
})

test_that("determine_fetch_requirements validates inputs", {
  expect_error(determine_fetch_requirements("not_df"), "single-row data.frame")

  multi_row <- dplyr::bind_rows(
    create_default_ticker_tracking("AAPL"),
    create_default_ticker_tracking("MSFT")
  )
  expect_error(determine_fetch_requirements(multi_row), "single-row data.frame")

  single_row <- create_default_ticker_tracking("AAPL")
  expect_error(
    determine_fetch_requirements(single_row, reference_date = "2024-12-15"),
    "Date object"
  )
})

test_that("update_earnings_prediction updates tracking correctly", {
  tracking <- create_default_ticker_tracking("AAPL")

  # nolint start
  # fmt: skip
  earnings_data <- tibble::tribble(
    ~fiscalDateEnding, ~reportedDate,
    "2024-03-31",      "2024-05-01",
    "2024-06-30",      "2024-08-01",
    "2024-09-30",      "2024-11-01"
  ) %>%
    dplyr::mutate(dplyr::across(c(fiscalDateEnding, reportedDate), as.Date))
  # nolint end

  updated <- update_earnings_prediction(tracking, "AAPL", earnings_data)

  expect_equal(updated$last_fiscal_date_ending, as.Date("2024-09-30"))
  expect_equal(updated$last_reported_date, as.Date("2024-11-01"))
  expect_equal(updated$median_report_delay_days, 32L)
  expect_false(is.na(updated$next_estimated_report_date))
})

test_that("update_earnings_prediction handles empty earnings data", {
  tracking <- create_default_ticker_tracking("AAPL")
  tracking$last_fiscal_date_ending <- as.Date("2024-06-30")

  earnings_data <- tibble::tibble(
    fiscalDateEnding = as.Date(character()),
    reportedDate = as.Date(character())
  )

  updated <- update_earnings_prediction(tracking, "AAPL", earnings_data)

  # Should remain unchanged
  expect_equal(updated$last_fiscal_date_ending, as.Date("2024-06-30"))
})

test_that("update_earnings_prediction validates inputs", {
  tracking <- create_empty_refresh_tracking()
  # nolint start
  # fmt: skip
  earnings_data <- tibble::tribble(
    ~fiscalDateEnding, ~reportedDate,
    "2024-09-30",      "2024-11-01"
  ) %>%
    dplyr::mutate(dplyr::across(c(fiscalDateEnding, reportedDate), as.Date))
  # nolint end

  expect_error(
    update_earnings_prediction("not_df", "AAPL", earnings_data),
    "data.frame"
  )
  expect_error(
    update_earnings_prediction(tracking, 123, earnings_data),
    "character scalar"
  )
  expect_error(
    update_earnings_prediction(tracking, "AAPL", "not_df"),
    "data.frame"
  )
})
