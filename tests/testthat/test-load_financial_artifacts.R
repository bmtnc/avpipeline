test_that("load_financial_artifacts returns list with correct structure", {
  # Skip if cache files don't exist
  skip_if_not(file.exists("cache/financial_statements_artifact.csv"))
  skip_if_not(file.exists("cache/market_cap_artifact_vectorized.csv"))
  skip_if_not(file.exists("cache/price_artifact.csv"))
  
  result <- load_financial_artifacts()
  
  # Check that result is a list
  expect_type(result, "list")
  
  # Check that all expected elements exist
  expect_true("financial_statements" %in% names(result))
  expect_true("market_cap_data" %in% names(result))
  expect_true("price_data" %in% names(result))
  
  # Check that each element is a data frame
  expect_true(is.data.frame(result$financial_statements))
  expect_true(is.data.frame(result$market_cap_data))
  expect_true(is.data.frame(result$price_data))
})

test_that("load_financial_artifacts loads financial statements with date columns", {
  skip_if_not(file.exists("cache/financial_statements_artifact.csv"))
  skip_if_not(file.exists("cache/market_cap_artifact_vectorized.csv"))
  skip_if_not(file.exists("cache/price_artifact.csv"))
  
  result <- load_financial_artifacts()
  
  # Check that financial statements has expected date columns
  expect_true("fiscalDateEnding" %in% names(result$financial_statements))
  expect_true("calendar_quarter_ending" %in% names(result$financial_statements))
  expect_true("reportedDate" %in% names(result$financial_statements))
  
  # Check that date columns are Date type
  expect_true(inherits(result$financial_statements$fiscalDateEnding, "Date"))
  expect_true(inherits(result$financial_statements$reportedDate, "Date"))
})

test_that("load_financial_artifacts loads market cap data with date columns", {
  skip_if_not(file.exists("cache/financial_statements_artifact.csv"))
  skip_if_not(file.exists("cache/market_cap_artifact_vectorized.csv"))
  skip_if_not(file.exists("cache/price_artifact.csv"))
  
  result <- load_financial_artifacts()
  
  # Check that market cap data has expected date columns
  expect_true("date" %in% names(result$market_cap_data))
  expect_true("reportedDate" %in% names(result$market_cap_data))
  
  # Check that date columns are Date type
  expect_true(inherits(result$market_cap_data$date, "Date"))
  expect_true(inherits(result$market_cap_data$reportedDate, "Date"))
})

test_that("load_financial_artifacts loads price data with date columns", {
  skip_if_not(file.exists("cache/financial_statements_artifact.csv"))
  skip_if_not(file.exists("cache/market_cap_artifact_vectorized.csv"))
  skip_if_not(file.exists("cache/price_artifact.csv"))
  
  result <- load_financial_artifacts()
  
  # Check that price data has expected date columns
  expect_true("date" %in% names(result$price_data))
  
  # Check that date column is Date type
  expect_true(inherits(result$price_data$date, "Date"))
})

test_that("load_financial_artifacts handles missing financial statements file", {
  # Skip if file actually exists (we're testing error handling)
  skip_if(file.exists("cache/financial_statements_artifact.csv"))

  expect_error(
    load_financial_artifacts(),
    "^Financial statements file does not exist: cache/financial_statements_artifact\\.csv$"
  )
})

test_that("load_financial_artifacts handles missing market cap file", {
  # This test would require mocking file.exists() to return true for some files but not others
  # For simplicity, we'll document that manual testing is needed for this edge case
  # or we'd need a more sophisticated mocking framework
  skip("Requires mocking framework to test partial file availability")
})

test_that("load_financial_artifacts handles missing price file", {
  # This test would require mocking file.exists() to return true for some files but not others
  skip("Requires mocking framework to test partial file availability")
})
