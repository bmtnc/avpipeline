test_that("add_per_share_columns creates correct per-share columns", {
  # nolint start
  # fmt: skip
  data <- tibble::tribble(
    ~ticker, ~revenue, ~assets, ~commonStockSharesOutstanding,
    "AAPL",  1000,     500,     100,
    "AAPL",  2000,     600,     200
  )
  # nolint end

  result <- add_per_share_columns(data, cols = c("revenue", "assets"))

  expect_true("revenue_per_share" %in% names(result))
  expect_true("assets_per_share" %in% names(result))
  expect_equal(result$revenue_per_share, c(10, 10))
  expect_equal(result$assets_per_share, c(5, 3))
})

test_that("add_per_share_columns handles NA in metrics", {
  # nolint start
  # fmt: skip
  data <- tibble::tribble(
    ~revenue, ~commonStockSharesOutstanding,
    1000,     100,
    NA,       100,
    3000,     100
  )
  # nolint end

  result <- add_per_share_columns(data, cols = "revenue")

  expect_equal(result$revenue_per_share[1], 10)
  expect_true(is.na(result$revenue_per_share[2]))
  expect_equal(result$revenue_per_share[3], 30)
})

test_that("add_per_share_columns handles NA and zero shares", {
  # nolint start
  # fmt: skip
  data <- tibble::tribble(
    ~revenue, ~commonStockSharesOutstanding,
    1000,     100,
    2000,     NA,
    3000,     0
  )
  # nolint end

  result <- add_per_share_columns(data, cols = "revenue")

  expect_equal(result$revenue_per_share[1], 10)
  expect_true(is.na(result$revenue_per_share[2]))
  expect_true(is.na(result$revenue_per_share[3]))
})

test_that("add_per_share_columns skips columns already ending in _per_share", {
  # nolint start
  # fmt: skip
  data <- tibble::tribble(
    ~revenue, ~revenue_per_share, ~commonStockSharesOutstanding,
    1000,     5,                  100,
    2000,     10,                 200
  )
  # nolint end

  result <- add_per_share_columns(
    data,
    cols = c("revenue", "revenue_per_share")
  )

  # Should only have one revenue_per_share column (the new calculated one)
  expect_equal(sum(names(result) == "revenue_per_share"), 1)
  expect_equal(result$revenue_per_share, c(10, 10))
})

test_that("add_per_share_columns uses custom shares column", {
  # nolint start
  # fmt: skip
  data <- tibble::tribble(
    ~revenue, ~my_shares,
    1000,     50,
    2000,     100
  )
  # nolint end

  result <- add_per_share_columns(
    data,
    cols = "revenue",
    shares_col = "my_shares"
  )

  expect_equal(result$revenue_per_share, c(20, 20))
})

test_that("add_per_share_columns returns original data when no valid cols", {
  # nolint start
  # fmt: skip
  data <- tibble::tribble(
    ~revenue_per_share, ~commonStockSharesOutstanding,
    10,                 100,
    20,                 200
  )
  # nolint end

  result <- add_per_share_columns(data, cols = "revenue_per_share")

  expect_equal(ncol(result), ncol(data))
})
