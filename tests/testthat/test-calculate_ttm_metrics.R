make_flow_data <- function(ticker, dates, values, series_run_id = NULL) {
  data <- tibble::tibble(
    ticker = ticker,
    fiscalDateEnding = as.Date(dates),
    operatingCashflow = values
  )
  if (!is.null(series_run_id)) {
    data$series_run_id <- series_run_id
  }
  data
}

test_that("TTM is the rolling 4-quarter sum within a ticker", {
  data <- make_flow_data(
    "A",
    c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31", "2021-03-31"),
    c(10, 20, 30, 40, 50)
  )

  result <- calculate_ttm_metrics(data, "operatingCashflow")

  expect_equal(
    result$operatingCashflow_ttm,
    c(NA, NA, NA, 100, 140)
  )
})

test_that("TTM does not sum across a series gap", {
  # Two runs: 4 quarters, then a gap, then 4 more quarters
  data <- make_flow_data(
    "A",
    c(
      "2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31",
      "2022-03-31", "2022-06-30", "2022-09-30", "2022-12-31"
    ),
    c(10, 20, 30, 40, 100, 200, 300, 400),
    series_run_id = c(1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L)
  )

  result <- calculate_ttm_metrics(data, "operatingCashflow")

  expect_equal(
    result$operatingCashflow_ttm,
    c(NA, NA, NA, 100, NA, NA, NA, 1000)
  )
})

test_that("a missing quarter yields NA, not an understated sum", {
  # Q3 unreported. Summing the other three would report 70 as a full year.
  data <- make_flow_data(
    "A",
    c(
      "2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31",
      "2021-03-31", "2021-06-30", "2021-09-30"
    ),
    c(10, 20, NA, 40, 50, 60, 70)
  )

  result <- calculate_ttm_metrics(data, "operatingCashflow")

  # The four windows overlapping the hole are NA; the fifth recovers.
  expect_equal(
    result$operatingCashflow_ttm,
    c(NA, NA, NA, NA, NA, NA, 220)
  )
})

test_that("a metric absent for every quarter is NA, not zero", {
  data <- make_flow_data(
    "A",
    c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31"),
    c(NA_real_, NA_real_, NA_real_, NA_real_)
  )

  result <- calculate_ttm_metrics(data, "operatingCashflow")

  expect_true(all(is.na(result$operatingCashflow_ttm)))
})

test_that("TTM groups by ticker only when series_run_id is absent", {
  data <- dplyr::bind_rows(
    make_flow_data(
      "A",
      c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31"),
      c(10, 20, 30, 40)
    ),
    make_flow_data(
      "B",
      c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31"),
      c(1, 2, 3, 4)
    )
  )

  result <- calculate_ttm_metrics(data, "operatingCashflow")

  expect_equal(
    result$operatingCashflow_ttm[result$ticker == "A"],
    c(NA, NA, NA, 100)
  )
  expect_equal(
    result$operatingCashflow_ttm[result$ticker == "B"],
    c(NA, NA, NA, 10)
  )
})
