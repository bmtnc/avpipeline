test_that("create_empty_refresh_tracking creates correct schema", {
  tracking <- create_empty_refresh_tracking()

  expect_s3_class(tracking, "tbl_df")
  expect_equal(nrow(tracking), 0)

  expected_cols <- c(
    "ticker", "price_last_fetched_at", "splits_last_fetched_at",
    "quarterly_last_fetched_at", "overview_last_fetched_at",
    "last_fiscal_date_ending", "last_reported_date",
    "next_estimated_report_date", "median_report_delay_days", "last_error_message",
    "is_active_ticker", "has_data_discrepancy", "last_version_date", "data_updated_at"
  )
  expect_equal(names(tracking), expected_cols)

  expect_type(tracking$ticker, "character")
  expect_s3_class(tracking$price_last_fetched_at, "POSIXct")
  expect_s3_class(tracking$last_fiscal_date_ending, "Date")
  expect_type(tracking$median_report_delay_days, "integer")
  expect_type(tracking$is_active_ticker, "logical")
})

test_that("create_default_ticker_tracking creates row with defaults", {
  row <- create_default_ticker_tracking("AAPL")

  expect_s3_class(row, "tbl_df")
  expect_equal(nrow(row), 1)
  expect_equal(row$ticker, "AAPL")
  expect_true(is.na(row$price_last_fetched_at))
  expect_true(is.na(row$quarterly_last_fetched_at))
  expect_true(is.na(row$last_fiscal_date_ending))
  expect_true(row$is_active_ticker)
  expect_false(row$has_data_discrepancy)
})

test_that("create_default_ticker_tracking validates inputs", {
  expect_error(create_default_ticker_tracking(123), "ticker")
  expect_error(create_default_ticker_tracking(""), "ticker")
  expect_error(create_default_ticker_tracking(c("A", "B")), "ticker")
})

test_that("get_ticker_tracking returns existing row", {
  tracking <- dplyr::bind_rows(
    create_default_ticker_tracking("AAPL"),
    create_default_ticker_tracking("MSFT")
  )
  tracking$price_last_fetched_at[1] <- as.POSIXct("2024-12-15 10:00:00")

  result <- get_ticker_tracking("AAPL", tracking)

  expect_equal(nrow(result), 1)
  expect_equal(result$ticker, "AAPL")
  expect_equal(result$price_last_fetched_at, as.POSIXct("2024-12-15 10:00:00"))
})

test_that("get_ticker_tracking creates default for missing ticker", {
  tracking <- create_default_ticker_tracking("AAPL")

  result <- get_ticker_tracking("MSFT", tracking)

  expect_equal(nrow(result), 1)
  expect_equal(result$ticker, "MSFT")
  expect_true(is.na(result$price_last_fetched_at))
})

test_that("get_ticker_tracking validates inputs", {
  tracking <- create_empty_refresh_tracking()

  expect_error(get_ticker_tracking(123, tracking), "ticker")
  expect_error(get_ticker_tracking("AAPL", "not_a_df"), "data.frame")
})

test_that("update_ticker_tracking updates existing ticker", {
  tracking <- create_default_ticker_tracking("AAPL")
  now <- Sys.time()

  updated <- update_ticker_tracking(tracking, "AAPL", list(
    price_last_fetched_at = now,
    is_active_ticker = FALSE
  ))

  expect_equal(nrow(updated), 1)
  expect_true(abs(as.numeric(updated$price_last_fetched_at - now)) < 1)
  expect_false(updated$is_active_ticker)
})

test_that("update_ticker_tracking adds new ticker if not exists", {
  tracking <- create_default_ticker_tracking("AAPL")
  now <- Sys.time()

  updated <- update_ticker_tracking(tracking, "MSFT", list(
    price_last_fetched_at = now
  ))

  expect_equal(nrow(updated), 2)
  expect_true("MSFT" %in% updated$ticker)

  msft_row <- dplyr::filter(updated, ticker == "MSFT")
  expect_true(abs(as.numeric(msft_row$price_last_fetched_at - now)) < 1)
})

test_that("update_ticker_tracking validates inputs", {
  tracking <- create_empty_refresh_tracking()

  expect_error(update_ticker_tracking("not_df", "AAPL", list()), "tracking")
  expect_error(update_ticker_tracking(tracking, 123, list()), "ticker")
  expect_error(update_ticker_tracking(tracking, "AAPL", "not_list"), "updates")
})

test_that("update_tracking_after_fetch updates price timestamp", {
  tracking <- create_default_ticker_tracking("AAPL")

  updated <- update_tracking_after_fetch(tracking, "AAPL", "price")

  expect_false(is.na(updated$price_last_fetched_at))
  expect_true(is.na(updated$splits_last_fetched_at))
  expect_true(is.na(updated$quarterly_last_fetched_at))
  expect_true(is.na(updated$last_error_message))
})

test_that("update_tracking_after_fetch updates quarterly with dates", {
  tracking <- create_default_ticker_tracking("AAPL")
  fiscal_date <- as.Date("2024-09-30")
  reported_date <- as.Date("2024-11-01")

  updated <- update_tracking_after_fetch(
    tracking, "AAPL", "quarterly",
    fiscal_date_ending = fiscal_date,
    reported_date = reported_date
  )

  expect_false(is.na(updated$quarterly_last_fetched_at))
  expect_equal(updated$last_fiscal_date_ending, fiscal_date)
  expect_equal(updated$last_reported_date, reported_date)
})

test_that("update_tracking_after_fetch sets data_updated_at when data changed", {
  tracking <- create_default_ticker_tracking("AAPL")

  updated_no_change <- update_tracking_after_fetch(
    tracking, "AAPL", "price", data_changed = FALSE
  )
  expect_true(is.na(updated_no_change$data_updated_at))

  updated_with_change <- update_tracking_after_fetch(
    tracking, "AAPL", "price", data_changed = TRUE
  )
  expect_false(is.na(updated_with_change$data_updated_at))
})

test_that("update_tracking_after_fetch updates overview timestamp", {
  tracking <- create_default_ticker_tracking("AAPL")

  updated <- update_tracking_after_fetch(tracking, "AAPL", "overview")

  expect_false(is.na(updated$overview_last_fetched_at))
  expect_true(is.na(updated$price_last_fetched_at))
  expect_true(is.na(updated$quarterly_last_fetched_at))
})

test_that("update_tracking_after_error records error message", {
  tracking <- create_default_ticker_tracking("AAPL")

  updated <- update_tracking_after_error(tracking, "AAPL", "API rate limit exceeded")

  expect_equal(updated$last_error_message, "API rate limit exceeded")
})

test_that("update_tracking_after_error validates inputs", {
  tracking <- create_empty_refresh_tracking()

  expect_error(update_tracking_after_error(tracking, "AAPL", 123), "error_message")
})
