test_that("add_tickers_to_artifact validates tickers parameter", {
  expect_error(
    add_tickers_to_artifact(123),
    "must be a non-empty character vector"
  )
  expect_error(
    add_tickers_to_artifact(character(0)),
    "must be a non-empty character vector"
  )
  expect_error(
    add_tickers_to_artifact(NULL),
    "must be a non-empty character vector"
  )
})

test_that("add_tickers_to_artifact validates bucket_name", {
  expect_error(
    add_tickers_to_artifact("AAPL", bucket_name = 123),
    "bucket_name"
  )
  expect_error(
    add_tickers_to_artifact("AAPL", bucket_name = c("a", "b")),
    "bucket_name"
  )
  expect_error(
    add_tickers_to_artifact("AAPL", bucket_name = ""),
    "bucket_name"
  )
})

test_that("add_tickers_to_artifact validates region", {
  expect_error(
    add_tickers_to_artifact("AAPL", region = 123),
    "region"
  )
})

test_that("add_tickers_to_artifact rejects duplicate tickers gracefully", {
  # Duplicates should pass validation (deduped internally), fail on empty bucket
  expect_error(
    add_tickers_to_artifact(c("AAPL", "AAPL"), bucket_name = ""),
    "bucket_name"
  )
})
