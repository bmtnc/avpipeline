# Test data
test_df <- tibble::tribble(
  ~ticker, ~date, ~value,
  "AAPL", "2020-01-01", 100,
  "AAPL", "2020-01-02", 105,
  "AAPL", "2020-01-03", 110,
  "AAPL", "2020-01-04", 115,
  "AAPL", "2020-01-05", 120,
  "MSFT", "2020-01-01", 200,
  "MSFT", "2020-01-02", 205,
  "MSFT", "2020-01-03", 210,
  "GOOG", "2020-01-01", 300,
  "GOOG", "2020-01-02", 305,
  "TSLA", "2020-01-01", 400
)

test_that("filters groups with sufficient observations correctly", {
  actual <- filter_sufficient_observations(test_df, "ticker", 3)
  expected <- tibble::tribble(
    ~ticker, ~date, ~value,
    "AAPL", "2020-01-01", 100,
    "AAPL", "2020-01-02", 105,
    "AAPL", "2020-01-03", 110,
    "AAPL", "2020-01-04", 115,
    "AAPL", "2020-01-05", 120,
    "MSFT", "2020-01-01", 200,
    "MSFT", "2020-01-02", 205,
    "MSFT", "2020-01-03", 210
  )
  
  expect_equal(actual, expected)
})

test_that("keeps groups with exactly min_obs observations", {
  actual <- filter_sufficient_observations(test_df, "ticker", 2)
  expected <- tibble::tribble(
    ~ticker, ~date, ~value,
    "AAPL", "2020-01-01", 100,
    "AAPL", "2020-01-02", 105,
    "AAPL", "2020-01-03", 110,
    "AAPL", "2020-01-04", 115,
    "AAPL", "2020-01-05", 120,
    "MSFT", "2020-01-01", 200,
    "MSFT", "2020-01-02", 205,
    "MSFT", "2020-01-03", 210,
    "GOOG", "2020-01-01", 300,
    "GOOG", "2020-01-02", 305
  )
  
  expect_equal(actual, expected)
})

test_that("returns all groups when all have sufficient observations", {
  actual <- filter_sufficient_observations(test_df, "ticker", 1)
  expected <- test_df
  
  expect_equal(actual, expected)
})

test_that("returns empty data frame when no groups have sufficient observations", {
  actual <- filter_sufficient_observations(test_df, "ticker", 10)
  expected <- test_df %>% dplyr::filter(FALSE)
  
  expect_equal(actual, expected)
})

test_that("works with different group column types", {
  test_df_numeric <- tibble::tribble(
    ~group_id, ~value,
    1, 100,
    1, 105,
    1, 110,
    2, 200,
    2, 205,
    3, 300
  )
  
  actual <- filter_sufficient_observations(test_df_numeric, "group_id", 2)
  expected <- tibble::tribble(
    ~group_id, ~value,
    1, 100,
    1, 105,
    1, 110,
    2, 200,
    2, 205
  )
  
  expect_equal(actual, expected)
})

test_that("preserves original column order", {
  actual <- filter_sufficient_observations(test_df, "ticker", 3)
  expected_names <- c("ticker", "date", "value")
  
  expect_equal(names(actual), expected_names)
})

test_that("handles single group correctly", {
  single_group_df <- tibble::tribble(
    ~ticker, ~value,
    "AAPL", 100,
    "AAPL", 105,
    "AAPL", 110
  )
  
  actual <- filter_sufficient_observations(single_group_df, "ticker", 2)
  expected <- single_group_df
  
  expect_equal(actual, expected)
})

test_that("fails when data is not data frame", {
  invalid_data <- c("not", "a", "data", "frame")
  
  expect_error(
    filter_sufficient_observations(invalid_data, "ticker", 3),
    "^Input data must be a data\\.frame\\. Received: character$"
  )
})

test_that("fails when data is empty data frame", {
  empty_df <- tibble::tribble(~ticker, ~value)
  
  expect_error(
    filter_sufficient_observations(empty_df, "ticker", 3),
    "data data.frame must have at least one row"
  )
})

test_that("fails when group_col is not character", {
  expect_error(
    filter_sufficient_observations(test_df, 123, 3),
    "^Argument 'group_col' must be single character string, received: numeric of length 1$"
  )
})

test_that("fails when group_col is not single value", {
  expect_error(
    filter_sufficient_observations(test_df, c("ticker", "date"), 3),
    "^Argument 'group_col' must be single character string, received: character of length 2$"
  )
})

test_that("fails when group_col is not in data", {
  expect_error(
    filter_sufficient_observations(test_df, "nonexistent", 3),
    "^Required columns missing from data: nonexistent\\. Available columns: ticker, date, value$"
  )
})

test_that("fails when min_obs is not numeric", {
  expect_error(
    filter_sufficient_observations(test_df, "ticker", "invalid"),
    "^Argument 'min_obs' must be single numeric value, received: character of length 1$"
  )
})

test_that("fails when min_obs is not single value", {
  expect_error(
    filter_sufficient_observations(test_df, "ticker", c(1, 2)),
    "^Argument 'min_obs' must be single numeric value, received: numeric of length 2$"
  )
})

test_that("fails when min_obs is negative", {
  expect_error(
    filter_sufficient_observations(test_df, "ticker", -1),
    "^Argument 'min_obs' must be positive integer, received: -1$"
  )
})

test_that("fails when min_obs is zero", {
  expect_error(
    filter_sufficient_observations(test_df, "ticker", 0),
    "^Argument 'min_obs' must be positive integer, received: 0$"
  )
})

test_that("fails when min_obs is NA", {
  expect_error(
    filter_sufficient_observations(test_df, "ticker", NA),
    "^Argument 'min_obs' must be single numeric value, received: logical of length 1$"
  )
})

test_that("converts decimal min_obs to integer", {
  actual <- filter_sufficient_observations(test_df, "ticker", 3.0)
  expected <- tibble::tribble(
    ~ticker, ~date, ~value,
    "AAPL", "2020-01-01", 100,
    "AAPL", "2020-01-02", 105,
    "AAPL", "2020-01-03", 110,
    "AAPL", "2020-01-04", 115,
    "AAPL", "2020-01-05", 120,
    "MSFT", "2020-01-01", 200,
    "MSFT", "2020-01-02", 205,
    "MSFT", "2020-01-03", 210
  )
  
  expect_equal(actual, expected)
})