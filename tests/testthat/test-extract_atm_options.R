test_that("extract_atm_options picks strike closest to spot", {
  chain <- tibble::tibble(
    ticker = "TEST",
    contractID = paste0("C", 1:6),
    date = as.Date("2025-01-10"),
    expiration = rep(as.Date("2025-02-21"), 6),
    strike = c(95, 100, 105, 95, 100, 105),
    type = c("call", "call", "call", "put", "put", "put"),
    implied_volatility = c(0.35, 0.30, 0.28, 0.36, 0.31, 0.29),
    last = rep(5, 6), mark = rep(5, 6),
    bid = rep(4.9, 6), bid_size = rep(10L, 6),
    ask = rep(5.1, 6), ask_size = rep(10L, 6),
    volume = rep(100L, 6), open_interest = rep(500L, 6),
    delta = rep(0.5, 6), gamma = rep(0.02, 6),
    theta = rep(-0.05, 6), vega = rep(0.2, 6), rho = rep(0.03, 6)
  )

  result <- extract_atm_options(chain, spot_price = 100)

  expect_equal(nrow(result), 2)  # one call, one put
  expect_equal(result$strike, c(100, 100))
  expect_equal(sort(result$type), c("call", "put"))
})

test_that("extract_atm_options respects moneyness threshold", {
  chain <- tibble::tibble(
    ticker = "TEST",
    contractID = paste0("C", 1:4),
    date = as.Date("2025-01-10"),
    expiration = rep(as.Date("2025-02-21"), 4),
    strike = c(80, 100, 120, 80),
    type = c("call", "call", "call", "put"),
    implied_volatility = c(0.40, 0.30, 0.25, 0.42),
    last = rep(5, 4), mark = rep(5, 4),
    bid = rep(4.9, 4), bid_size = rep(10L, 4),
    ask = rep(5.1, 4), ask_size = rep(10L, 4),
    volume = rep(100L, 4), open_interest = rep(500L, 4),
    delta = rep(0.5, 4), gamma = rep(0.02, 4),
    theta = rep(-0.05, 4), vega = rep(0.2, 4), rho = rep(0.03, 4)
  )

  # With tight threshold, only strike=100 is within 5% of spot=100
  result <- extract_atm_options(chain, spot_price = 100, moneyness_threshold = 0.05)

  expect_equal(nrow(result), 1)
  expect_equal(result$strike, 100)
  expect_equal(result$type, "call")
})

test_that("extract_atm_options handles multiple expirations", {
  chain <- tibble::tibble(
    ticker = "TEST",
    contractID = paste0("C", 1:4),
    date = as.Date("2025-01-10"),
    expiration = c(
      as.Date("2025-02-21"), as.Date("2025-02-21"),
      as.Date("2025-03-21"), as.Date("2025-03-21")
    ),
    strike = c(100, 100, 100, 100),
    type = c("call", "put", "call", "put"),
    implied_volatility = c(0.30, 0.31, 0.28, 0.29),
    last = rep(5, 4), mark = rep(5, 4),
    bid = rep(4.9, 4), bid_size = rep(10L, 4),
    ask = rep(5.1, 4), ask_size = rep(10L, 4),
    volume = rep(100L, 4), open_interest = rep(500L, 4),
    delta = rep(0.5, 4), gamma = rep(0.02, 4),
    theta = rep(-0.05, 4), vega = rep(0.2, 4), rho = rep(0.03, 4)
  )

  result <- extract_atm_options(chain, spot_price = 100)

  expect_equal(nrow(result), 4)  # 2 expirations x 2 types
})

test_that("extract_atm_options returns empty for empty chain", {
  chain <- tibble::tibble(
    ticker = character(), contractID = character(),
    date = as.Date(character()), expiration = as.Date(character()),
    strike = numeric(), type = character(),
    implied_volatility = numeric(),
    last = numeric(), mark = numeric(),
    bid = numeric(), bid_size = integer(),
    ask = numeric(), ask_size = integer(),
    volume = integer(), open_interest = integer(),
    delta = numeric(), gamma = numeric(),
    theta = numeric(), vega = numeric(), rho = numeric()
  )

  result <- extract_atm_options(chain, spot_price = 100)
  expect_equal(nrow(result), 0)
})

test_that("extract_atm_options returns empty for invalid spot price", {
  chain <- tibble::tibble(
    ticker = "TEST", contractID = "C1",
    date = as.Date("2025-01-10"), expiration = as.Date("2025-02-21"),
    strike = 100, type = "call", implied_volatility = 0.30,
    last = 5, mark = 5, bid = 4.9, bid_size = 10L,
    ask = 5.1, ask_size = 10L, volume = 100L, open_interest = 500L,
    delta = 0.5, gamma = 0.02, theta = -0.05, vega = 0.2, rho = 0.03
  )

  expect_equal(nrow(extract_atm_options(chain, spot_price = NA)), 0)
  expect_equal(nrow(extract_atm_options(chain, spot_price = 0)), 0)
  expect_equal(nrow(extract_atm_options(chain, spot_price = -100)), 0)
})
