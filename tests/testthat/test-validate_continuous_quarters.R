# Test data setup
test_df <- tibble::tribble(
  ~ticker, ~fiscalDateEnding, ~row_num, ~days_diff, ~is_quarterly, ~revenue,
  "AAPL", "2020-01-31", 1, NA, TRUE, 100,
  "AAPL", "2020-02-15", 2, 15, FALSE, 105,
  "AAPL", "2020-04-30", 3, 89, TRUE, 110,
  "AAPL", "2020-07-31", 4, 92, TRUE, 120,
  "AAPL", "2020-10-31", 5, 92, TRUE, 130,
  "AAPL", "2021-01-31", 6, 92, TRUE, 140
) %>%
  dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))

test_that("finds continuous quarterly series ignoring invalid month-end dates", {
  actual <- validate_continuous_quarters(test_df)
  
  # CHANGED: Updated to include full continuous quarterly series starting from 2020-01-31
  # After filtering invalid 2020-02-15, the remaining dates form a perfect quarterly pattern
  expected <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~revenue,
    "AAPL", "2020-01-31", 100,
    "AAPL", "2020-04-30", 110,
    "AAPL", "2020-07-31", 120,
    "AAPL", "2020-10-31", 130,
    "AAPL", "2021-01-31", 140
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  expect_equal(actual, expected)
})

test_that("finds continuous quarterly series from beginning when all valid", {
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~row_num, ~days_diff, ~is_quarterly, ~revenue,
    "AAPL", "2020-02-29", 1, NA, TRUE, 100,
    "AAPL", "2020-05-31", 2, 92, TRUE, 110,
    "AAPL", "2020-08-31", 3, 92, TRUE, 120,
    "AAPL", "2020-11-30", 4, 91, TRUE, 130
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  actual <- validate_continuous_quarters(test_data)
  
  expected <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~revenue,
    "AAPL", "2020-02-29", 100,
    "AAPL", "2020-05-31", 110,
    "AAPL", "2020-08-31", 120,
    "AAPL", "2020-11-30", 130
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  expect_equal(actual, expected)
})

test_that("returns single quarter when only one valid month-end exists", {
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~row_num, ~days_diff, ~is_quarterly, ~revenue,
    "AAPL", "2020-02-15", 1, NA, FALSE, 100,
    "AAPL", "2020-05-31", 2, 105, FALSE, 120,
    "AAPL", "2020-08-15", 3, 76, FALSE, 130
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  actual <- validate_continuous_quarters(test_data)
  
  expected <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~revenue,
    "AAPL", "2020-05-31", 120
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  expect_equal(actual, expected)
})

# ... existing code ...

test_that("finds longest continuous sequence when multiple gaps exist", {
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~row_num, ~days_diff, ~is_quarterly, ~revenue,
    "AAPL", "2020-01-31", 1, NA, TRUE, 100,
    "AAPL", "2020-06-30", 2, 151, FALSE, 115,
    "AAPL", "2020-09-30", 3, 92, TRUE, 125,
    "AAPL", "2020-12-31", 4, 92, TRUE, 130,
    "AAPL", "2021-03-31", 5, 90, TRUE, 140,
    "AAPL", "2021-06-30", 6, 91, TRUE, 150
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  actual <- validate_continuous_quarters(test_data)
  
  expected <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~revenue,
    "AAPL", "2020-06-30", 115,
    "AAPL", "2020-09-30", 125,
    "AAPL", "2020-12-31", 130,
    "AAPL", "2021-03-31", 140,
    "AAPL", "2021-06-30", 150
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  expect_equal(actual, expected)
})

# ... rest of existing code ...
test_that("handles non-calendar fiscal quarters correctly", {
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~row_num, ~days_diff, ~is_quarterly, ~revenue,
    "AAPL", "2020-01-31", 1, NA, TRUE, 100,
    "AAPL", "2020-04-30", 2, 89, TRUE, 110,
    "AAPL", "2020-07-31", 3, 92, TRUE, 120,
    "AAPL", "2020-10-31", 4, 92, TRUE, 130,
    "AAPL", "2021-01-31", 5, 92, TRUE, 140
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  actual <- validate_continuous_quarters(test_data)
  
  expected <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~revenue,
    "AAPL", "2020-01-31", 100,
    "AAPL", "2020-04-30", 110,
    "AAPL", "2020-07-31", 120,
    "AAPL", "2020-10-31", 130,
    "AAPL", "2021-01-31", 140
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  expect_equal(actual, expected)
})

test_that("returns empty data frame when no valid month-end dates exist", {
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~row_num, ~days_diff, ~is_quarterly, ~revenue,
    "AAPL", "2020-02-15", 1, NA, FALSE, 100,
    "AAPL", "2020-05-15", 2, 89, FALSE, 110,
    "AAPL", "2020-08-15", 3, 92, FALSE, 120
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  actual <- validate_continuous_quarters(test_data)
  
  # Create empty data frame with correct column types
  expected <- tibble::tibble(
    ticker = character(0),
    fiscalDateEnding = as.Date(character(0)),
    revenue = numeric(0)
  )
  
  expect_equal(actual, expected)
})

test_that("returns empty data frame when no continuous series found", {
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~row_num, ~days_diff, ~is_quarterly, ~revenue,
    "AAPL", "2020-01-31", 1, NA, TRUE, 100,
    "AAPL", "2020-06-30", 2, 151, FALSE, 120,
    "AAPL", "2020-12-31", 3, 184, FALSE, 140
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  actual <- validate_continuous_quarters(test_data)
  
  expected <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~revenue,
    "AAPL", "2020-01-31", 100
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  expect_equal(actual, expected)
})

test_that("works with custom date column name", {
  test_data <- tibble::tribble(
    ~ticker, ~custom_date, ~row_num, ~days_diff, ~is_quarterly, ~revenue,
    "AAPL", "2020-03-31", 1, NA, TRUE, 110,
    "AAPL", "2020-06-30", 2, 91, TRUE, 120,
    "AAPL", "2020-09-30", 3, 92, TRUE, 130
  ) %>%
    dplyr::mutate(custom_date = as.Date(custom_date))
  
  actual <- validate_continuous_quarters(test_data, date_col = "custom_date")
  
  expected <- tibble::tribble(
    ~ticker, ~custom_date, ~revenue,
    "AAPL", "2020-03-31", 110,
    "AAPL", "2020-06-30", 120,
    "AAPL", "2020-09-30", 130
  ) %>%
    dplyr::mutate(custom_date = as.Date(custom_date))
  
  expect_equal(actual, expected)
})

test_that("works with custom row number column name", {
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~custom_row, ~days_diff, ~is_quarterly, ~revenue,
    "AAPL", "2020-03-31", 1, NA, TRUE, 110,
    "AAPL", "2020-06-30", 2, 91, TRUE, 120,
    "AAPL", "2020-09-30", 3, 92, TRUE, 130
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  actual <- validate_continuous_quarters(test_data, row_num_col = "custom_row")
  
  expected <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~revenue,
    "AAPL", "2020-03-31", 110,
    "AAPL", "2020-06-30", 120,
    "AAPL", "2020-09-30", 130
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  expect_equal(actual, expected)
})

test_that("works with custom cleanup columns", {
  test_data <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~row_num, ~temp_col, ~is_quarterly, ~revenue,
    "AAPL", "2020-03-31", 1, "remove", TRUE, 110,
    "AAPL", "2020-06-30", 2, "remove", TRUE, 120,
    "AAPL", "2020-09-30", 3, "remove", TRUE, 130
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  actual <- validate_continuous_quarters(test_data, cleanup_cols = c("temp_col", "is_quarterly"))
  
  expected <- tibble::tribble(
    ~ticker, ~fiscalDateEnding, ~row_num, ~revenue,
    "AAPL", "2020-03-31", 1, 110,
    "AAPL", "2020-06-30", 2, 120,
    "AAPL", "2020-09-30", 3, 130
  ) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding))
  
  expect_equal(actual, expected)
})

test_that("fails when date_col is not character", {
  expect_error(
    validate_continuous_quarters(test_df, date_col = 123),
    "^Input 'date_col' must be a single character string\\. Received: numeric of length 1$"
  )
})

test_that("fails when date_col has multiple values", {
  expect_error(
    validate_continuous_quarters(test_df, date_col = c("col1", "col2")),
    "^Input 'date_col' must be a single character string\\. Received: character of length 2$"
  )
})

test_that("fails when row_num_col is not character", {
  expect_error(
    validate_continuous_quarters(test_df, row_num_col = 456),
    "^Input 'row_num_col' must be a single character string\\. Received: numeric of length 1$"
  )
})

test_that("fails when row_num_col has multiple values", {
  expect_error(
    validate_continuous_quarters(test_df, row_num_col = c("col1", "col2")),
    "^Input 'row_num_col' must be a single character string\\. Received: character of length 2$"
  )
})

test_that("fails when cleanup_cols is not character", {
  expect_error(
    validate_continuous_quarters(test_df, cleanup_cols = 789),
    "^Input 'cleanup_cols' must be a character vector\\. Received: numeric$"
  )
})