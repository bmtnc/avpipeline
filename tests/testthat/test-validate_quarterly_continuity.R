test_that("validate_quarterly_continuity validates financial_statements parameter", {
  expect_error(
    validate_quarterly_continuity("not a df"),
    "^Input data must be a data\\.frame\\. Received: character$"
  )
})

test_that("validate_quarterly_continuity validates required columns", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tribble(
    ~wrong_col,
    "A",
    "B"
  )
  # nolint end

  expect_error(
    validate_quarterly_continuity(test_data),
    "^Required columns missing from data: ticker, fiscalDateEnding\\. Available columns: wrong_col$"
  )
})

make_quarters <- function(ticker, dates) {
  tibble::tibble(
    ticker = ticker,
    fiscalDateEnding = as.Date(dates),
    metric1 = seq_along(dates)
  )
}

test_that("continuous series is a single run with no gaps flagged", {
  data <- make_quarters("A", c("2020-03-31", "2020-06-30", "2020-09-30"))

  result <- validate_quarterly_continuity(data)

  expect_equal(nrow(result), 3)
  expect_equal(result$series_run_id, c(1L, 1L, 1L))
  expect_equal(result$gap_before, c(FALSE, FALSE, FALSE))
  expect_equal(result$has_discontinuous_series, c(FALSE, FALSE, FALSE))
})

test_that("all quarters are kept across a gap, with the gap annotated", {
  # RH scenario: missing 2022-10-31 must not discard either side of the gap
  data <- make_quarters(
    "RH",
    c("2022-01-31", "2022-04-30", "2022-07-31", "2023-01-31", "2023-04-30")
  )

  result <- validate_quarterly_continuity(data)

  expect_equal(nrow(result), 5)
  expect_equal(result$series_run_id, c(1L, 1L, 1L, 2L, 2L))
  expect_equal(result$gap_before, c(FALSE, FALSE, FALSE, TRUE, FALSE))
  expect_true(all(result$has_discontinuous_series))
})

test_that("non-month-end dates are dropped", {
  data <- make_quarters("A", c("2020-03-31", "2020-06-15", "2020-09-30"))

  result <- validate_quarterly_continuity(data)

  expect_equal(as.character(result$fiscalDateEnding), c("2020-03-31", "2020-09-30"))
})

test_that("tickers are annotated independently", {
  gapped <- make_quarters("GAP", c("2020-03-31", "2020-06-30", "2021-06-30"))
  continuous <- make_quarters("CON", c("2020-03-31", "2020-06-30"))

  result <- validate_quarterly_continuity(dplyr::bind_rows(gapped, continuous))

  con_rows <- dplyr::filter(result, ticker == "CON")
  gap_rows <- dplyr::filter(result, ticker == "GAP")
  expect_false(any(con_rows$has_discontinuous_series))
  expect_true(all(gap_rows$has_discontinuous_series))
  expect_equal(gap_rows$series_run_id, c(1L, 1L, 2L))
})

test_that("non-calendar fiscal quarters stay continuous (retail Feb/May/Aug/Nov)", {
  data <- make_quarters(
    "A",
    c("2020-02-29", "2020-05-31", "2020-08-31", "2020-11-30", "2021-02-28")
  )

  result <- validate_quarterly_continuity(data)

  expect_equal(result$series_run_id, rep(1L, 5))
  expect_false(any(result$gap_before))
})
