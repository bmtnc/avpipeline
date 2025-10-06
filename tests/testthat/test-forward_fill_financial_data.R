test_that("forward_fill_financial_data fills missing values forward", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tibble(
    ticker           = c("AAPL",  "AAPL",     "AAPL",  "AAPL"),
    date             = as.Date(c("2023-01-01", "2023-01-02", "2023-01-03", "2023-01-04")),
    totalRevenue_ttm = c(400000,  NA_real_,   NA_real_, NA_real_),
    ebit_ttm         = c(50000,   NA_real_,   NA_real_, NA_real_)
  )
  # nolint end
  
  result <- forward_fill_financial_data(input_data)
  
  # Check that NA values were filled forward
  expect_equal(result$totalRevenue_ttm, c(400000, 400000, 400000, 400000))
  expect_equal(result$ebit_ttm, c(50000, 50000, 50000, 50000))
})

test_that("forward_fill_financial_data handles multiple tickers separately", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tibble(
    ticker           = c("AAPL",  "AAPL",     "MSFT",  "MSFT"),
    date             = as.Date(c("2023-01-01", "2023-01-02", "2023-01-01", "2023-01-02")),
    totalRevenue_ttm = c(400000,  NA_real_,   300000,  NA_real_)
  )
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
  input_data <- tibble::tibble(
    ticker           = c("AAPL",     "AAPL",     "AAPL"),
    date             = as.Date(c("2023-01-01", "2023-01-02", "2023-01-03")),
    totalRevenue_ttm = c(NA_real_,  400000,     NA_real_)
  )
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
  input_data <- tibble::tibble(
    ticker           = c("AAPL",  "AAPL"),
    date             = as.Date(c("2023-01-01", "2023-01-02")),
    totalRevenue_ttm = c(400000,  410000)
  )
  # nolint end
  
  result <- forward_fill_financial_data(input_data)
  
  # Values should remain unchanged
  expect_equal(result$totalRevenue_ttm, c(400000, 410000))
})

test_that("forward_fill_financial_data updates with new financial data", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tibble(
    ticker           = c("AAPL",  "AAPL",     "AAPL",  "AAPL",     "AAPL"),
    date             = as.Date(c("2023-01-01", "2023-01-02", "2023-01-03", "2023-01-04", "2023-01-05")),
    totalRevenue_ttm = c(400000,  NA_real_,   NA_real_, 420000,     NA_real_)
  )
  # nolint end
  
  result <- forward_fill_financial_data(input_data)
  
  # Should fill forward until new data appears
  expect_equal(result$totalRevenue_ttm, c(400000, 400000, 400000, 420000, 420000))
})

test_that("forward_fill_financial_data validates input type", {
  expect_error(
    forward_fill_financial_data("not_a_dataframe"),
    "^forward_fill_financial_data\\(\\): \\[data\\] must be a data.frame, not character$"
  )
  
  expect_error(
    forward_fill_financial_data(list(a = 1, b = 2)),
    "^forward_fill_financial_data\\(\\): \\[data\\] must be a data.frame, not list$"
  )
})

test_that("forward_fill_financial_data validates required columns", {
  # Missing ticker column
  invalid_data <- tibble::tibble(
    date = as.Date(c("2023-01-01", "2023-01-02")),
    totalRevenue_ttm = c(400000, NA_real_)
  )
  
  expect_error(
    forward_fill_financial_data(invalid_data),
    "^forward_fill_financial_data\\(\\): \\[data\\] must contain 'ticker' column$"
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
  input_data <- tibble::tibble(
    ticker           = c("AAPL",  "AAPL"),
    date             = as.Date(c("2023-01-01", "2023-01-02")),
    totalRevenue_ttm = c(NA_real_, NA_real_)
  )
  # nolint end
  
  result <- forward_fill_financial_data(input_data)
  
  # All values should remain NA
  expect_true(all(is.na(result$totalRevenue_ttm)))
})

test_that("forward_fill_financial_data preserves non-numeric columns", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tibble(
    ticker               = c("AAPL",  "AAPL",     "AAPL"),
    date                 = as.Date(c("2023-01-01", "2023-01-02", "2023-01-03")),
    totalRevenue_ttm     = c(400000,  NA_real_,   NA_real_),
    fiscal_quarter       = c("Q4",    NA,         NA)
  )
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
  input_data <- tibble::tibble(
    ticker           = c("AAPL",  "AAPL"),
    date             = as.Date(c("2023-01-01", "2023-01-02")),
    totalRevenue_ttm = c(400000,  NA_real_)
  )
  # nolint end
  
  result <- forward_fill_financial_data(input_data)
  
  # Should not be grouped
  expect_false(dplyr::is_grouped_df(result))
})
