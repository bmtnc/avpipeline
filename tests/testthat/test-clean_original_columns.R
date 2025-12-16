# Test data
test_df <- tibble::tribble(
  ~ticker, ~date, ~metric1, ~metric2, ~metric1_anomaly, ~metric2_anomaly,
  "AAPL", "2020-01-01", 100, 200, FALSE, FALSE,
  "AAPL", "2020-02-01", 110, 210, FALSE, FALSE,
  "AAPL", "2020-03-01", 500, 220, TRUE, FALSE,
  "AAPL", "2020-04-01", 120, 230, FALSE, FALSE,
  "MSFT", "2020-01-01", 80, 160, FALSE, FALSE,
  "MSFT", "2020-02-01", 90, 170, FALSE, FALSE,
  "MSFT", "2020-03-01", 300, 180, TRUE, FALSE,
  "MSFT", "2020-04-01", 100, 190, FALSE, FALSE
)

test_that("cleans anomalous values and interpolates correctly", {
  metric_cols <- c("metric1", "metric2")
  actual <- clean_original_columns(test_df, metric_cols)
  
  # Should interpolate anomalous values in metric1
  expect_equal(actual$metric1[3], 115)  # AAPL 2020-03-01: interpolated between 110 and 120
  expect_equal(actual$metric1[7], 95)   # MSFT 2020-03-01: interpolated between 90 and 100
  
  # Should keep original values for metric2 (no anomalies)
  expect_equal(actual$metric2, test_df$metric2)
})

test_that("preserves anomaly flag columns", {
  metric_cols <- c("metric1", "metric2")
  actual <- clean_original_columns(test_df, metric_cols)
  
  expect_true("metric1_anomaly" %in% names(actual))
  expect_true("metric2_anomaly" %in% names(actual))
  expect_equal(actual$metric1_anomaly, test_df$metric1_anomaly)
  expect_equal(actual$metric2_anomaly, test_df$metric2_anomaly)
})

test_that("returns original data unchanged when no anomaly columns exist", {
  test_df_no_anomaly <- test_df %>% dplyr::select(-metric1_anomaly, -metric2_anomaly)
  metric_cols <- c("metric1", "metric2")
  
  expect_warning(
    expect_warning(
      actual <- clean_original_columns(test_df_no_anomaly, metric_cols),
      "Anomaly column 'metric1_anomaly' not found for metric 'metric1'. Skipping cleaning."
    ),
    "Anomaly column 'metric2_anomaly' not found for metric 'metric2'. Skipping cleaning."
  )
  
  expect_equal(actual$metric1, test_df_no_anomaly$metric1)
  expect_equal(actual$metric2, test_df_no_anomaly$metric2)
})

test_that("handles partial anomaly columns gracefully", {
  test_df_partial <- test_df %>% dplyr::select(-metric2_anomaly)
  metric_cols <- c("metric1", "metric2")
  
  expect_warning(
    actual <- clean_original_columns(test_df_partial, metric_cols),
    "Anomaly column 'metric2_anomaly' not found for metric 'metric2'. Skipping cleaning."
  )
  
  # Should clean metric1 but not metric2
  expect_equal(actual$metric1[3], 115)  # interpolated
  expect_equal(actual$metric2, test_df_partial$metric2)  # unchanged
})

test_that("returns original data when all values are anomalous", {
  test_df_all_anomalies <- test_df %>%
    dplyr::mutate(
      metric1_anomaly = TRUE,
      metric2_anomaly = TRUE
    )
  
  metric_cols <- c("metric1", "metric2")
  actual <- clean_original_columns(test_df_all_anomalies, metric_cols)
  
  # Should handle all-NA case gracefully (zoo::na.approx should fail and keep original)
  expect_equal(nrow(actual), nrow(test_df_all_anomalies))
  expect_true(all(names(test_df_all_anomalies) %in% names(actual)))
})

test_that("processes single metric column correctly", {
  metric_cols <- c("metric1")
  actual <- clean_original_columns(test_df, metric_cols)
  
  expect_equal(actual$metric1[3], 115)  # interpolated
  expect_equal(actual$metric2, test_df$metric2)  # unchanged
})

test_that("handles empty data frame", {
  empty_df <- test_df[0, ]
  metric_cols <- c("metric1", "metric2")
  
  expect_error(
    clean_original_columns(empty_df, metric_cols),
    "data data.frame must have at least one row"
  )
})

test_that("fails when metric_cols is not character", {
  metric_cols <- c(1, 2)
  
  expect_error(
    clean_original_columns(test_df, metric_cols),
    "^Argument 'metric_cols' must be non-empty character vector, received: numeric of length 2$"
  )
})

test_that("fails when metric_cols is empty", {
  metric_cols <- character(0)
  
  expect_error(
    clean_original_columns(test_df, metric_cols),
    "^Argument 'metric_cols' must be non-empty character vector, received: character of length 0$"
  )
})

test_that("fails when metric_cols is NULL", {
  metric_cols <- NULL
  
  expect_error(
    clean_original_columns(test_df, metric_cols),
    "^Argument 'metric_cols' must be non-empty character vector, received: NULL of length 0$"
  )
})

test_that("preserves all original columns and adds no new columns", {
  metric_cols <- c("metric1", "metric2")
  actual <- clean_original_columns(test_df, metric_cols)
  
  expect_equal(names(actual), names(test_df))
  expect_equal(nrow(actual), nrow(test_df))
})