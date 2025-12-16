test_that("fetch_and_store_single_data_type validates ticker parameter", {
  expect_error(
    fetch_and_store_single_data_type(123, "price", "bucket", "key"),
    "character scalar"
  )
  expect_error(
    fetch_and_store_single_data_type(c("A", "B"), "price", "bucket", "key"),
    "character scalar"
  )
})

test_that("fetch_and_store_single_data_type validates data_type parameter", {
  expect_error(
    fetch_and_store_single_data_type("AAPL", 123, "bucket", "key"),
    "character scalar"
  )
  expect_error(
    fetch_and_store_single_data_type("AAPL", c("a", "b"), "bucket", "key"),
    "character scalar"
  )
})

test_that("fetch_and_store_single_data_type validates bucket_name parameter", {
  expect_error(
    fetch_and_store_single_data_type("AAPL", "price", 123, "key"),
    "character scalar"
  )
  expect_error(
    fetch_and_store_single_data_type("AAPL", "price", c("a", "b"), "key"),
    "character scalar"
  )
})

test_that("fetch_and_store_single_data_type returns error for unknown data_type", {
  result <- fetch_and_store_single_data_type(
    "AAPL",
    "unknown_type",
    "bucket",
    "api_key"
  )
  expect_false(result$success)
  expect_null(result$data)
  expect_match(result$error, "Unknown data_type")
})

# TODO: Integration tests require actual API and S3 access
# - Test successful fetch and store for each data type
# - Test version snapshot creation
# - Test error handling when API fails
