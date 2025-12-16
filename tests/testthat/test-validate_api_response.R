test_that("validate_api_response succeeds with valid response", {
  valid_response <- list(quarterlyReports = data.frame(a = 1))
  expect_null(validate_api_response(valid_response))
})

test_that("validate_api_response errors on Error Message", {
  error_response <- list(`Error Message` = "Invalid API call")
  expect_error(
    validate_api_response(error_response),
    "Alpha Vantage API error: Invalid API call"
  )
})

test_that("validate_api_response errors on rate limit Note", {
  rate_limit_response <- list(Note = "API call frequency exceeded")
  expect_error(
    validate_api_response(rate_limit_response),
    "Alpha Vantage API rate limit: API call frequency exceeded"
  )
})

test_that("validate_api_response succeeds with empty response", {
  empty_response <- list()
  expect_null(validate_api_response(empty_response))
})
