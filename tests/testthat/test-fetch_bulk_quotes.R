# Network is not exercised: both guards reject before any request is built.

test_that("rejects an empty symbol vector", {
  expect_error(fetch_bulk_quotes(character(0)), "non-empty")
})

test_that("rejects more than 100 symbols", {
  expect_error(fetch_bulk_quotes(rep("AAA", 101)), "100 symbols")
})

test_that("rejects a non-character symbols argument", {
  expect_error(fetch_bulk_quotes(1:5), "character")
})
