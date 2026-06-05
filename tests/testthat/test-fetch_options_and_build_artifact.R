test_that("fetch_options_and_build_artifact validates tickers parameter", {
  expect_error(
    fetch_options_and_build_artifact(character(0)),
    "non-empty character vector"
  )
  expect_error(
    fetch_options_and_build_artifact(123),
    "non-empty character vector"
  )
  expect_error(
    fetch_options_and_build_artifact(NULL),
    "non-empty character vector"
  )
})

test_that("fetch_options_and_build_artifact validates bucket_name", {
  expect_error(
    fetch_options_and_build_artifact("AAPL", bucket_name = ""),
    "bucket_name"
  )
})
