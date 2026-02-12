test_that("fetch_earnings_estimates validates ticker parameter", {
  expect_error(
    fetch_earnings_estimates(123),
    "character"
  )
  expect_error(
    fetch_earnings_estimates(c("A", "B")),
    "scalar"
  )
  expect_error(
    fetch_earnings_estimates(""),
    "empty"
  )
})
