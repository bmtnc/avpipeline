test_that("forward_fill_financial_data fills missing values forward", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~totalRevenue_ttm, ~ebit_ttm,
    "AAPL",  "2023-01-01", 400000,            50000,
    "AAPL",  "2023-01-02", NA_real_,          NA_real_,
    "AAPL",  "2023-01-03", NA_real_,          NA_real_,
    "AAPL",  "2023-01-04", NA_real_,          NA_real_
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  result <- forward_fill_financial_data(input_data)

  # Check that NA values were filled forward
  expect_equal(result$totalRevenue_ttm, c(400000, 400000, 400000, 400000))
  expect_equal(result$ebit_ttm, c(50000, 50000, 50000, 50000))
})

test_that("forward_fill_financial_data handles multiple tickers separately", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~totalRevenue_ttm,
    "AAPL",  "2023-01-01", 400000,
    "AAPL",  "2023-01-02", NA_real_,
    "MSFT",  "2023-01-01", 300000,
    "MSFT",  "2023-01-02", NA_real_
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  result <- forward_fill_financial_data(input_data)

  # AAPL rows should fill forward with AAPL values
  aapl_rows <- result[result$ticker == "AAPL", ]
  expect_equal(aapl_rows$totalRevenue_ttm, c(400000, 400000))

  # MSFT rows should fill forward with MSFT values
  msft_rows <- result[result$ticker == "MSFT", ]
  expect_equal(msft_rows$totalRevenue_ttm, c(300000, 300000))
})

test_that("forward_fill_financial_data does not fill backwards", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~totalRevenue_ttm,
    "AAPL",  "2023-01-01", NA_real_,
    "AAPL",  "2023-01-02", 400000,
    "AAPL",  "2023-01-03", NA_real_
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  result <- forward_fill_financial_data(input_data)

  # First row should remain NA (no backward fill)
  expect_true(is.na(result$totalRevenue_ttm[1]))

  # Second and third rows should be filled
  expect_equal(result$totalRevenue_ttm[2], 400000)
  expect_equal(result$totalRevenue_ttm[3], 400000)
})

test_that("forward_fill_financial_data handles data with no NAs", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~totalRevenue_ttm,
    "AAPL",  "2023-01-01", 400000,
    "AAPL",  "2023-01-02", 410000
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  result <- forward_fill_financial_data(input_data)

  # Values should remain unchanged
  expect_equal(result$totalRevenue_ttm, c(400000, 410000))
})

test_that("forward_fill_financial_data updates with new financial data", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~totalRevenue_ttm,
    "AAPL",  "2023-01-01", 400000,
    "AAPL",  "2023-01-02", NA_real_,
    "AAPL",  "2023-01-03", NA_real_,
    "AAPL",  "2023-01-04", 420000,
    "AAPL",  "2023-01-05", NA_real_
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  result <- forward_fill_financial_data(input_data)

  # Should fill forward until new data appears
  expect_equal(
    result$totalRevenue_ttm,
    c(400000, 400000, 400000, 420000, 420000)
  )
})

test_that("forward_fill_financial_data handles empty data frames", {
  # nolint start
  # fmt: skip
  empty_data <- tibble::tibble(
    ticker           = character(0),
    date             = as.Date(character(0)),
    totalRevenue_ttm = numeric(0)
  )
  # nolint end

  result <- forward_fill_financial_data(empty_data)

  # Should return empty data frame with same structure
  expect_equal(nrow(result), 0)
  expect_true("ticker" %in% names(result))
})

test_that("forward_fill_financial_data handles all NA columns", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~totalRevenue_ttm,
    "AAPL",  "2023-01-01", NA_real_,
    "AAPL",  "2023-01-02", NA_real_
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  result <- forward_fill_financial_data(input_data)

  # All values should remain NA
  expect_true(all(is.na(result$totalRevenue_ttm)))
})

test_that("forward_fill_financial_data preserves non-numeric columns", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~totalRevenue_ttm, ~fiscal_quarter,
    "AAPL",  "2023-01-01", 400000,            "Q4",
    "AAPL",  "2023-01-02", NA_real_,          NA,
    "AAPL",  "2023-01-03", NA_real_,          NA
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  result <- forward_fill_financial_data(input_data)

  # Numeric column filled
  expect_equal(result$totalRevenue_ttm, c(400000, 400000, 400000))

  # Character column also filled
  expect_equal(result$fiscal_quarter, c("Q4", "Q4", "Q4"))
})

test_that("forward_fill_financial_data returns ungrouped data", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~totalRevenue_ttm,
    "AAPL",  "2023-01-01", 400000,
    "AAPL",  "2023-01-02", NA_real_
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  result <- forward_fill_financial_data(input_data)

  # Should not be grouped
  expect_false(dplyr::is_grouped_df(result))
})

test_that("fill respects series runs: post-gap NA TTM is not backfilled from a prior run", {
  # Daily rows joined with two quarterly runs. Run 2's first quarterly row has
  # NA TTM (fewer than 4 quarters in its run); run 1's value must not leak
  # through it.
  # nolint start
  # fmt: skip
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~series_run_id, ~totalRevenue_ttm,
    "RH",    "2022-09-15", 1L,             3858081000,
    "RH",    "2022-09-16", NA_integer_,    NA_real_,
    "RH",    "2023-03-30", 2L,             NA_real_,
    "RH",    "2023-03-31", NA_integer_,    NA_real_
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end

  result <- forward_fill_financial_data(input_data)

  # Gap-period row inherits the prior run and its value (staleness cap bounds it)
  expect_equal(result$series_run_id, c(1L, 1L, 2L, 2L))
  expect_equal(
    result$totalRevenue_ttm,
    c(3858081000, 3858081000, NA_real_, NA_real_)
  )
})
