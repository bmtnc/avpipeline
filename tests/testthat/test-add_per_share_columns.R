test_that("add_per_share_columns creates correct per-share columns", {
  data <- tibble::tibble(
    ticker = c("AAPL", "AAPL"),
    revenue = c(1000, 2000),
    assets = c(500, 600),
    commonStockSharesOutstanding = c(100, 200)
  )

  result <- add_per_share_columns(data, cols = c("revenue", "assets"))

  expect_true("revenue_per_share" %in% names(result))
  expect_true("assets_per_share" %in% names(result))
  expect_equal(result$revenue_per_share, c(10, 10))
  expect_equal(result$assets_per_share, c(5, 3))
})

test_that("add_per_share_columns handles NA in metrics", {
  data <- tibble::tibble(
    revenue = c(1000, NA, 3000),
    commonStockSharesOutstanding = c(100, 100, 100)
  )

  result <- add_per_share_columns(data, cols = "revenue")

  expect_equal(result$revenue_per_share[1], 10)
  expect_true(is.na(result$revenue_per_share[2]))
  expect_equal(result$revenue_per_share[3], 30)
})

test_that("add_per_share_columns handles NA and zero shares", {
  data <- tibble::tibble(
    revenue = c(1000, 2000, 3000),
    commonStockSharesOutstanding = c(100, NA, 0)
  )

  result <- add_per_share_columns(data, cols = "revenue")

  expect_equal(result$revenue_per_share[1], 10)
  expect_true(is.na(result$revenue_per_share[2]))
  expect_true(is.na(result$revenue_per_share[3]))
})

test_that("add_per_share_columns skips columns already ending in _per_share", {
  data <- tibble::tibble(
    revenue = c(1000, 2000),
    revenue_per_share = c(5, 10),
    commonStockSharesOutstanding = c(100, 200)
  )

  result <- add_per_share_columns(data, cols = c("revenue", "revenue_per_share"))

  # Should only have one revenue_per_share column (the new calculated one)
  expect_equal(sum(names(result) == "revenue_per_share"), 1)
  expect_equal(result$revenue_per_share, c(10, 10))
})

test_that("add_per_share_columns uses custom shares column", {
  data <- tibble::tibble(
    revenue = c(1000, 2000),
    my_shares = c(50, 100)
  )

  result <- add_per_share_columns(data, cols = "revenue", shares_col = "my_shares")

  expect_equal(result$revenue_per_share, c(20, 20))
})

test_that("add_per_share_columns returns original data when no valid cols", {
  data <- tibble::tibble(
    revenue_per_share = c(10, 20),
    commonStockSharesOutstanding = c(100, 200)
  )

  result <- add_per_share_columns(data, cols = "revenue_per_share")

  expect_equal(ncol(result), ncol(data))
})
