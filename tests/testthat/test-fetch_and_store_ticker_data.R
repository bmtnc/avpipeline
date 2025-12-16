test_that("fetch_and_store_ticker_data validates ticker parameter", {
  mock_tracking <- create_default_ticker_tracking("TEST")
  expect_error(
    fetch_and_store_ticker_data(123, list(), mock_tracking, "bucket", "key"),
    "character scalar"
  )
  expect_error(
    fetch_and_store_ticker_data(c("A", "B"), list(), mock_tracking, "bucket", "key"),
    "character scalar"
  )
})

test_that("fetch_and_store_ticker_data validates fetch_requirements parameter", {
  mock_tracking <- create_default_ticker_tracking("AAPL")
  expect_error(
    fetch_and_store_ticker_data("AAPL", "not_a_list", mock_tracking, "bucket", "key"),
    "must be a list"
  )
})

test_that("fetch_and_store_ticker_data validates bucket_name parameter", {
  mock_tracking <- create_default_ticker_tracking("AAPL")
  expect_error(
    fetch_and_store_ticker_data("AAPL", list(), mock_tracking, 123, "key"),
    "character scalar"
  )
  expect_error(
    fetch_and_store_ticker_data("AAPL", list(), mock_tracking, c("a", "b"), "key"),
    "character scalar"
  )
})

# TODO: Integration tests require actual API and S3 access
# - Test fetching only price when requirements specify price=TRUE
# - Test fetching all quarterly when requirements specify quarterly=TRUE
# - Test that results contain expected structure per data type
