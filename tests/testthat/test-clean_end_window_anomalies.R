# Test data setup
test_df <- tibble::tribble(
  ~ticker, ~fiscalDateEnding, ~revenue, ~ebitda, ~netIncome,
  "AAPL", "2020-03-31", 58313, 13273, 11249,
  "AAPL", "2020-06-30", 59685, 14053, 11253, 
  "AAPL", "2020-09-30", 64698, 16120, 12673,
  "AAPL", "2020-12-31", 111439, 28755, 28755,
  "AAPL", "2021-03-31", 89584, 24353, 23630,
  "AAPL", "2021-06-30", 81434, 21744, 21744,
  "AAPL", "2021-09-30", 83360, 23071, 20551,
  "AAPL", "2021-12-31", 123945, 34630, 34630,
  "AAPL", "2022-03-31", 97278, 27987, 25010,
  "AAPL", "2022-06-30", 82959, 23075, 19442,
  "AAPL", "2022-09-30", 90146, 24094, 20721,
  "AAPL", "2022-12-31", 117154, 32972, 29998,
  "AAPL", "2023-03-31", 94836, 26920, 24160,
  "AAPL", "2023-06-30", 81797, 22340, 19881,
  "AAPL", "2023-09-30", 500000, 400000, 300000,  # Anomaly at end
  "MSFT", "2020-03-31", 35021, 13373, 10755,
  "MSFT", "2020-06-30", 38033, 15049, 11202,
  "MSFT", "2020-09-30", 37154, 15734, 13893,
  "MSFT", "2020-12-31", 43076, 18366, 15463,
  "MSFT", "2021-03-31", 41706, 16907, 15457,
  "MSFT", "2021-06-30", 46152, 19095, 16458,
  "MSFT", "2021-09-30", 45317, 20498, 20505,
  "MSFT", "2021-12-31", 51728, 22245, 18765,
  "MSFT", "2022-03-31", 49360, 20390, 16728,
  "MSFT", "2022-06-30", 51865, 20077, 16740,
  "MSFT", "2022-09-30", 50122, 21518, 17556,
  "MSFT", "2022-12-31", 52747, 20399, 16425,
  "MSFT", "2023-03-31", 52857, 21835, 18299,
  "MSFT", "2023-06-30", 56189, 24261, 20081,
  "MSFT", "2023-09-30", 56517, 22318, 22291
) %>%
  dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))

test_that("cleans end-window anomalies successfully", {
  actual <- clean_end_window_anomalies(test_df, c("revenue", "ebitda"))
  
  # AAPL should have the anomaly cleaned (forward filled from previous value)
  aapl_data <- actual %>% dplyr::filter(ticker == "AAPL")
  expect_true(aapl_data$revenue[15] == aapl_data$revenue[14])  # Should be forward filled
  expect_true(aapl_data$ebitda[15] == aapl_data$ebitda[14])   # Should be forward filled
  
  # MSFT should be unchanged (no end-window anomalies)
  msft_original <- test_df %>% dplyr::filter(ticker == "MSFT")
  msft_actual <- actual %>% dplyr::filter(ticker == "MSFT")
  expect_equal(msft_actual$revenue, msft_original$revenue)
})

test_that("returns original data when no anomalies detected", {
  # Create data with consistent ~5% growth (no anomalies)
  normal_data <- tibble::tribble(
    ~ticker, ~revenue, ~ebitda,
    "TEST", 100, 20,
    "TEST", 105, 21,
    "TEST", 110, 22,
    "TEST", 116, 23,    # Changed from 115 to maintain ~5% growth
    "TEST", 122, 24,    # Changed from 120
    "TEST", 128, 25,    # Changed from 125
    "TEST", 134, 26,    # Changed from 128  
    "TEST", 141, 27,    # Changed from 130
    "TEST", 148, 28,    # Changed from 135
    "TEST", 155, 29,    # Changed from 140
    "TEST", 163, 30,    # Changed from 145
    "TEST", 171, 31     # Changed from 150
  )
  
  actual <- clean_end_window_anomalies(normal_data, c("revenue", "ebitda"))
  expected <- normal_data
  
  expect_equal(actual, expected)
})

test_that("handles single ticker data correctly", {
  single_ticker <- test_df %>% dplyr::filter(ticker == "AAPL")
  
  actual <- clean_end_window_anomalies(single_ticker, "revenue")
  
  # Should clean the anomaly
  expect_true(actual$revenue[15] == actual$revenue[14])
  expect_equal(nrow(actual), nrow(single_ticker))
})

test_that("handles custom end_window_size parameter", {
  actual <- clean_end_window_anomalies(test_df, "revenue", end_window_size = 3)
  
  # Should still clean the AAPL anomaly as it's in the last 3 observations
  aapl_data <- actual %>% dplyr::filter(ticker == "AAPL")
  expect_true(aapl_data$revenue[15] == aapl_data$revenue[14])
})

test_that("handles custom threshold parameter", {
  # Use a very high threshold that shouldn't flag the anomaly
  actual <- clean_end_window_anomalies(test_df, "revenue", threshold = 50)
  
  # Should not clean the anomaly due to high threshold
  aapl_data <- actual %>% dplyr::filter(ticker == "AAPL")
  expect_equal(aapl_data$revenue[15], 500000)  # Original anomalous value preserved
})

test_that("handles custom min_observations parameter", {
  # Create small dataset that won't meet min_observations
  small_data <- tibble::tribble(
    ~ticker, ~revenue,
    "TEST", 100,
    "TEST", 110,
    "TEST", 1000  # Anomaly but insufficient data
  )
  
  actual <- clean_end_window_anomalies(small_data, "revenue", min_observations = 5)
  expected <- small_data
  
  expect_equal(actual, expected)  # Should be unchanged due to insufficient observations
})

test_that("handles data with all NA values in metric column", {
  na_data <- tibble::tribble(
    ~ticker, ~revenue, ~ebitda,
    "TEST", NA_real_, 100,
    "TEST", NA_real_, 105,
    "TEST", NA_real_, 110,
    "TEST", NA_real_, 115,
    "TEST", NA_real_, 120,
    "TEST", NA_real_, 125,
    "TEST", NA_real_, 130,
    "TEST", NA_real_, 135,
    "TEST", NA_real_, 140,
    "TEST", NA_real_, 145,
    "TEST", NA_real_, 150,
    "TEST", NA_real_, 155
  )
  
  actual <- clean_end_window_anomalies(na_data, c("revenue", "ebitda"))
  
  # Revenue column should remain all NA, ebitda should be processed normally
  expect_true(all(is.na(actual$revenue)))
  expect_equal(length(actual$ebitda), length(na_data$ebitda))
})

test_that("preserves non-metric columns", {
  actual <- clean_end_window_anomalies(test_df, "revenue")
  
  expect_true("fiscalDateEnding" %in% names(actual))
  expect_true("ticker" %in% names(actual))
  expect_true("ebitda" %in% names(actual))  # Unprocessed metric preserved
  expect_true("netIncome" %in% names(actual))  # Unprocessed metric preserved
})

test_that("fails when metric_cols is not character vector", {
  expect_error(
    clean_end_window_anomalies(test_df, 123),
    "^Argument 'metric_cols' must be non-empty character vector, received: numeric of length 1$"
  )
})

test_that("fails when metric_cols is empty", {
  expect_error(
    clean_end_window_anomalies(test_df, character(0)),
    "^metric_cols must not be empty \\(length 0\\)$"
  )
})

test_that("fails when end_window_size is not positive integer", {
  expect_error(
    clean_end_window_anomalies(test_df, "revenue", end_window_size = 0),
    "^end_window_size must be >= 1\\. Received: 0$"
  )
})

test_that("fails when threshold is not positive numeric", {
  expect_error(
    clean_end_window_anomalies(test_df, "revenue", threshold = -1),
    "^threshold must be greater than 0\\. Received: -1$"
  )
})

test_that("fails when min_observations is not positive integer", {
  expect_error(
    clean_end_window_anomalies(test_df, "revenue", min_observations = 0),
    "^min_observations must be >= 1\\. Received: 0$"
  )
})

test_that("handles unusual data without errors", {
  # Create data with very small alternating values
  unusual_data <- tibble::tribble(
    ~ticker, ~revenue,
    "TEST", 1e-10,
    "TEST", 2e-10,
    "TEST", 1e-10,
    "TEST", 2e-10,
    "TEST", 1e-10,
    "TEST", 2e-10,
    "TEST", 1e-10,
    "TEST", 2e-10,
    "TEST", 1e-10,
    "TEST", 2e-10,
    "TEST", 1e-10,
    "TEST", 2e-10
  )
  
  # Should not throw an error
  expect_no_error(
    actual <- clean_end_window_anomalies(unusual_data, "revenue")
  )
  
  # Should return a data frame with the same number of rows
  expect_equal(nrow(actual), nrow(unusual_data))
})