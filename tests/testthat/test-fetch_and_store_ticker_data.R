test_that("fetch_and_store_ticker_data validates ticker parameter", {
  expect_error(
    fetch_and_store_ticker_data(123, list(), "bucket", "key"),
    "character scalar"
  )
  expect_error(
    fetch_and_store_ticker_data(c("A", "B"), list(), "bucket", "key"),
    "character scalar"
  )
})

test_that("fetch_and_store_ticker_data validates fetch_requirements parameter", {
  expect_error(
    fetch_and_store_ticker_data("AAPL", "not_a_list", "bucket", "key"),
    "must be a list"
  )
})

test_that("fetch_and_store_ticker_data validates bucket_name parameter", {
  expect_error(
    fetch_and_store_ticker_data("AAPL", list(), 123, "key"),
    "character scalar"
  )
  expect_error(
    fetch_and_store_ticker_data("AAPL", list(), c("a", "b"), "key"),
    "character scalar"
  )
})

# TODO: Integration tests require actual API and S3 access
# - Test fetching only price when requirements specify price=TRUE
# - Test fetching all quarterly when requirements specify quarterly=TRUE
# - Test that results contain expected structure per data type
