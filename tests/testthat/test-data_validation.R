test_that("validate_quarterly_consistency returns valid for NULL existing data", {
  new_data <- tibble::tibble(
    ticker = "AAPL",
    fiscalDateEnding = as.Date("2024-09-30"),
    totalRevenue = 100000
  )

  result <- validate_quarterly_consistency(NULL, new_data)

  expect_true(result$valid)
  expect_null(result$mismatches)
})

test_that("validate_quarterly_consistency returns valid for empty existing data", {
  existing_data <- tibble::tibble(
    ticker = character(),
    fiscalDateEnding = as.Date(character()),
    totalRevenue = numeric()
  )

  new_data <- tibble::tibble(
    ticker = "AAPL",
    fiscalDateEnding = as.Date("2024-09-30"),
    totalRevenue = 100000
  )

  result <- validate_quarterly_consistency(existing_data, new_data)

  expect_true(result$valid)
  expect_null(result$mismatches)
})

test_that("validate_quarterly_consistency returns valid when data matches", {
  existing_data <- tibble::tibble(
    ticker = rep("AAPL", 3),
    fiscalDateEnding = as.Date(c("2024-03-31", "2024-06-30", "2024-09-30")),
    totalRevenue = c(90000, 95000, 100000),
    netIncome = c(20000, 21000, 22000)
  )

  new_data <- tibble::tibble(
    ticker = rep("AAPL", 4),
    fiscalDateEnding = as.Date(c("2024-03-31", "2024-06-30", "2024-09-30", "2024-12-31")),
    totalRevenue = c(90000, 95000, 100000, 105000),
    netIncome = c(20000, 21000, 22000, 23000)
  )

  result <- validate_quarterly_consistency(existing_data, new_data)

  expect_true(result$valid)
  expect_null(result$mismatches)
})

test_that("validate_quarterly_consistency detects mismatches", {
  existing_data <- tibble::tibble(
    ticker = rep("AAPL", 3),
    fiscalDateEnding = as.Date(c("2024-03-31", "2024-06-30", "2024-09-30")),
    totalRevenue = c(90000, 95000, 100000),
    netIncome = c(20000, 21000, 22000)
  )

  # Q2 revenue changed from 95000 to 96000
  new_data <- tibble::tibble(
    ticker = rep("AAPL", 4),
    fiscalDateEnding = as.Date(c("2024-03-31", "2024-06-30", "2024-09-30", "2024-12-31")),
    totalRevenue = c(90000, 96000, 100000, 105000),
    netIncome = c(20000, 21000, 22000, 23000)
  )

  result <- validate_quarterly_consistency(existing_data, new_data)

  expect_false(result$valid)
  expect_equal(nrow(result$mismatches), 1)
  expect_equal(result$mismatches$fiscalDateEnding, as.Date("2024-06-30"))
})

test_that("validate_quarterly_consistency handles NA values correctly", {
  existing_data <- tibble::tibble(
    ticker = rep("AAPL", 2),
    fiscalDateEnding = as.Date(c("2024-03-31", "2024-06-30")),
    totalRevenue = c(90000, NA),
    netIncome = c(20000, 21000)
  )

  # NA to NA is not a mismatch
  new_data_same <- tibble::tibble(
    ticker = rep("AAPL", 2),
    fiscalDateEnding = as.Date(c("2024-03-31", "2024-06-30")),
    totalRevenue = c(90000, NA),
    netIncome = c(20000, 21000)
  )

  result_same <- validate_quarterly_consistency(existing_data, new_data_same)
  expect_true(result_same$valid)

  # NA to value is a mismatch
  new_data_diff <- tibble::tibble(
    ticker = rep("AAPL", 2),
    fiscalDateEnding = as.Date(c("2024-03-31", "2024-06-30")),
    totalRevenue = c(90000, 95000),
    netIncome = c(20000, 21000)
  )

  result_diff <- validate_quarterly_consistency(existing_data, new_data_diff)
  expect_false(result_diff$valid)
})

test_that("validate_quarterly_consistency respects tolerance", {
  existing_data <- tibble::tibble(
    ticker = "AAPL",
    fiscalDateEnding = as.Date("2024-09-30"),
    totalRevenue = 100000
  )

  # Small difference within tolerance
  new_data_small <- tibble::tibble(
    ticker = "AAPL",
    fiscalDateEnding = as.Date("2024-09-30"),
    totalRevenue = 100000.005
  )

  result_small <- validate_quarterly_consistency(existing_data, new_data_small, tolerance = 0.01)
  expect_true(result_small$valid)

  # Difference exceeds tolerance
  new_data_large <- tibble::tibble(
    ticker = "AAPL",
    fiscalDateEnding = as.Date("2024-09-30"),
    totalRevenue = 100001
  )

  result_large <- validate_quarterly_consistency(existing_data, new_data_large, tolerance = 0.01)
  expect_false(result_large$valid)
})

test_that("validate_quarterly_consistency handles missing metrics gracefully", {
  existing_data <- tibble::tibble(
    ticker = "AAPL",
    fiscalDateEnding = as.Date("2024-09-30"),
    totalRevenue = 100000
  )

  new_data <- tibble::tibble(
    ticker = "AAPL",
    fiscalDateEnding = as.Date("2024-09-30"),
    totalRevenue = 100000
  )

  # Request metrics that don't exist
  result <- validate_quarterly_consistency(
    existing_data, new_data,
    key_metrics = c("totalRevenue", "nonexistent_metric")
  )

  expect_true(result$valid)
})

test_that("validate_quarterly_consistency returns valid when no overlap", {
  existing_data <- tibble::tibble(
    ticker = "AAPL",
    fiscalDateEnding = as.Date("2024-03-31"),
    totalRevenue = 90000
  )

  new_data <- tibble::tibble(
    ticker = "AAPL",
    fiscalDateEnding = as.Date("2024-09-30"),
    totalRevenue = 100000
  )

  result <- validate_quarterly_consistency(existing_data, new_data)

  expect_true(result$valid)
  expect_null(result$mismatches)
})

test_that("detect_data_loss returns no loss for NULL existing data", {
  new_data <- tibble::tibble(
    fiscalDateEnding = as.Date(c("2024-06-30", "2024-09-30")),
    value = c(100, 200)
  )

  result <- detect_data_loss(NULL, new_data)

  expect_false(result$has_loss)
  expect_equal(result$existing_count, 0L)
  expect_equal(result$new_count, 2L)
})

test_that("detect_data_loss detects fewer quarters", {
  existing_data <- tibble::tibble(
    fiscalDateEnding = as.Date(c("2024-03-31", "2024-06-30", "2024-09-30")),
    value = c(100, 200, 300)
  )

  new_data <- tibble::tibble(
    fiscalDateEnding = as.Date(c("2024-06-30", "2024-09-30")),
    value = c(200, 300)
  )

  result <- detect_data_loss(existing_data, new_data)

  expect_true(result$has_loss)
  expect_equal(result$existing_count, 3L)
  expect_equal(result$new_count, 2L)
})

test_that("detect_data_loss returns no loss when counts equal or greater", {
  existing_data <- tibble::tibble(
    fiscalDateEnding = as.Date(c("2024-06-30", "2024-09-30")),
    value = c(200, 300)
  )

  new_data <- tibble::tibble(
    fiscalDateEnding = as.Date(c("2024-06-30", "2024-09-30", "2024-12-31")),
    value = c(200, 300, 400)
  )

  result <- detect_data_loss(existing_data, new_data)

  expect_false(result$has_loss)
  expect_equal(result$existing_count, 2L)
  expect_equal(result$new_count, 3L)
})

test_that("detect_data_loss validates inputs", {
  existing_data <- tibble::tibble(fiscalDateEnding = as.Date("2024-09-30"))

  expect_error(detect_data_loss(existing_data, "not_df"), "data.frame")
})

# TODO: test log_data_discrepancy (requires S3 access)
