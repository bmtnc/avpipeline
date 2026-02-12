make_test_chain <- function(expirations, strikes, types, ivs,
                            observation_date = as.Date("2025-01-10")) {
  n <- length(expirations)
  tibble::tibble(
    ticker = rep("TEST", n),
    contractID = paste0("C", seq_len(n)),
    date = rep(observation_date, n),
    expiration = as.Date(expirations),
    strike = strikes,
    type = types,
    last = rep(5, n), mark = rep(5, n),
    bid = rep(4.9, n), bid_size = rep(10L, n),
    ask = rep(5.1, n), ask_size = rep(10L, n),
    volume = rep(100L, n), open_interest = rep(500L, n),
    implied_volatility = ivs,
    delta = rep(0.5, n), gamma = rep(0.02, n),
    theta = rep(-0.05, n), vega = rep(0.2, n), rho = rep(0.03, n)
  )
}

test_that("calculate_iv_term_structure returns correct structure", {
  chain <- make_test_chain(
    expirations = rep(c("2025-02-10", "2025-03-10"), each = 2),
    strikes = rep(100, 4),
    types = rep(c("call", "put"), 2),
    ivs = c(0.30, 0.32, 0.28, 0.29)
  )

  result <- calculate_iv_term_structure(chain, spot_price = 100,
                                         observation_date = as.Date("2025-01-10"))

  expect_s3_class(result, "tbl_df")
  expected_cols <- c("ticker", "observation_date", "expiration",
                     "days_to_expiration", "atm_iv",
                     "atm_iv_call", "atm_iv_put", "atm_strike", "spot_price")
  expect_equal(names(result), expected_cols)
  expect_equal(nrow(result), 2)
})

test_that("calculate_iv_term_structure averages call/put IV", {
  chain <- make_test_chain(
    expirations = rep("2025-02-10", 2),
    strikes = c(100, 100),
    types = c("call", "put"),
    ivs = c(0.30, 0.32)
  )

  result <- calculate_iv_term_structure(chain, spot_price = 100,
                                         observation_date = as.Date("2025-01-10"))

  expect_equal(nrow(result), 1)
  expect_equal(result$atm_iv, 0.31)  # mean of 0.30 and 0.32
  expect_equal(result$atm_iv_call, 0.30)
  expect_equal(result$atm_iv_put, 0.32)
})

test_that("calculate_iv_term_structure uses only available type when other is missing", {
  # Only call available
  chain <- make_test_chain(
    expirations = "2025-02-10",
    strikes = 100,
    types = "call",
    ivs = 0.30
  )

  result <- calculate_iv_term_structure(chain, spot_price = 100,
                                         observation_date = as.Date("2025-01-10"))

  expect_equal(nrow(result), 1)
  expect_equal(result$atm_iv, 0.30)
  expect_equal(result$atm_iv_call, 0.30)
  expect_true(is.na(result$atm_iv_put))
})

test_that("calculate_iv_term_structure calculates DTE correctly", {
  chain <- make_test_chain(
    expirations = "2025-04-10",  # 90 days from 2025-01-10
    strikes = 100,
    types = "call",
    ivs = 0.30
  )

  result <- calculate_iv_term_structure(chain, spot_price = 100,
                                         observation_date = as.Date("2025-01-10"))

  expect_equal(result$days_to_expiration, 90)
})

test_that("calculate_iv_term_structure filters expired options", {
  chain <- make_test_chain(
    expirations = c("2025-01-05", "2025-02-10"),  # first is before observation
    strikes = c(100, 100),
    types = c("call", "call"),
    ivs = c(0.30, 0.28)
  )

  result <- calculate_iv_term_structure(chain, spot_price = 100,
                                         observation_date = as.Date("2025-01-10"))

  expect_equal(nrow(result), 1)
  expect_equal(result$expiration, as.Date("2025-02-10"))
})

test_that("calculate_iv_term_structure filters zero/NA IV", {
  chain <- make_test_chain(
    expirations = rep("2025-02-10", 2),
    strikes = c(100, 100),
    types = c("call", "put"),
    ivs = c(0, NA)
  )

  result <- calculate_iv_term_structure(chain, spot_price = 100,
                                         observation_date = as.Date("2025-01-10"))

  expect_equal(nrow(result), 0)
})

test_that("calculate_iv_term_structure returns empty for empty chain", {
  chain <- make_test_chain(
    expirations = character(),
    strikes = numeric(),
    types = character(),
    ivs = numeric()
  )

  result <- calculate_iv_term_structure(chain, spot_price = 100,
                                         observation_date = as.Date("2025-01-10"))

  expect_equal(nrow(result), 0)
  expect_true("atm_iv" %in% names(result))
})

test_that("calculate_iv_term_structure returns empty for invalid spot", {
  chain <- make_test_chain(
    expirations = "2025-02-10",
    strikes = 100,
    types = "call",
    ivs = 0.30
  )

  result <- calculate_iv_term_structure(chain, spot_price = NA,
                                         observation_date = as.Date("2025-01-10"))
  expect_equal(nrow(result), 0)
})

test_that("calculate_iv_term_structure is sorted by DTE ascending", {
  chain <- make_test_chain(
    expirations = c("2025-06-10", "2025-02-10", "2025-04-10"),
    strikes = rep(100, 3),
    types = rep("call", 3),
    ivs = c(0.25, 0.30, 0.28)
  )

  result <- calculate_iv_term_structure(chain, spot_price = 100,
                                         observation_date = as.Date("2025-01-10"))

  expect_equal(result$days_to_expiration, sort(result$days_to_expiration))
})
