# Tests for process_batch_responses and parse_response_by_type

# --- parse_response_by_type ---

test_that("parse_response_by_type errors on unknown data_type", {
  expect_error(
    parse_response_by_type(NULL, "AAPL", "unknown_type"),
    "Unknown data_type"
  )
})

# --- process_batch_responses ---

test_that("process_batch_responses handles error responses gracefully", {
  err <- simpleError("Connection timed out")

  request_specs <- list(
    list(ticker = "AAPL", data_type = "price", extra_params = list(outputsize = "full")),
    list(ticker = "AAPL", data_type = "splits", extra_params = list())
  )

  responses <- list(err, err)

  results <- process_batch_responses(responses, request_specs, "test-bucket", "us-east-1")

  expect_true("AAPL" %in% names(results))
  expect_false(results$AAPL$price$success)
  expect_equal(results$AAPL$price$error, "Connection timed out")
  expect_false(results$AAPL$splits$success)
})

test_that("process_batch_responses groups results by ticker", {
  err <- simpleError("test error")

  request_specs <- list(
    list(ticker = "AAPL", data_type = "price", extra_params = list(outputsize = "full")),
    list(ticker = "MSFT", data_type = "price", extra_params = list(outputsize = "full")),
    list(ticker = "AAPL", data_type = "splits", extra_params = list())
  )

  responses <- list(err, err, err)

  results <- process_batch_responses(responses, request_specs, "test-bucket", "us-east-1")

  expect_equal(sort(names(results)), c("AAPL", "MSFT"))
  expect_true("price" %in% names(results$AAPL))
  expect_true("splits" %in% names(results$AAPL))
  expect_true("price" %in% names(results$MSFT))
})

test_that("process_batch_responses preserves outputsize_used", {
  err <- simpleError("test error")

  request_specs <- list(
    list(ticker = "AAPL", data_type = "price", extra_params = list(outputsize = "full"))
  )

  responses <- list(err)

  results <- process_batch_responses(responses, request_specs, "test-bucket", "us-east-1")
  expect_equal(results$AAPL$price$outputsize_used, "full")
})

test_that("process_batch_responses handles empty response list", {
  results <- process_batch_responses(list(), list(), "test-bucket", "us-east-1")
  expect_length(results, 0)
})
