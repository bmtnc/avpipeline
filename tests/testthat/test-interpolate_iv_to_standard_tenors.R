test_that("interpolate_iv_to_standard_tenors interpolates correctly", {
  term_structure <- tibble::tibble(
    ticker = rep("TEST", 3),
    observation_date = rep(as.Date("2025-01-10"), 3),
    expiration = as.Date(c("2025-02-09", "2025-04-10", "2026-01-10")),
    days_to_expiration = c(30, 90, 365),
    atm_iv = c(0.30, 0.26, 0.22),
    atm_iv_call = c(0.29, 0.25, 0.21),
    atm_iv_put = c(0.31, 0.27, 0.23),
    atm_strike = rep(100, 3),
    spot_price = rep(100, 3)
  )

  result <- interpolate_iv_to_standard_tenors(term_structure)

  expect_s3_class(result, "tbl_df")
  expect_equal(names(result), c("ticker", "observation_date", "tenor_days", "iv"))
  expect_equal(nrow(result), 5)  # 30, 60, 90, 180, 365

  # Known points should be exact
  expect_equal(result$iv[result$tenor_days == 30], 0.30)
  expect_equal(result$iv[result$tenor_days == 90], 0.26)
  expect_equal(result$iv[result$tenor_days == 365], 0.22)

  # Interpolated: 60d should be between 30d (0.30) and 90d (0.26)
  iv_60 <- result$iv[result$tenor_days == 60]
  expect_true(iv_60 > 0.26 && iv_60 < 0.30)
  # Linear interpolation: 0.30 + (60-30)/(90-30) * (0.26-0.30) = 0.30 - 0.02 = 0.28
  expect_equal(iv_60, 0.28)
})

test_that("interpolate_iv_to_standard_tenors does not extrapolate", {
  term_structure <- tibble::tibble(
    ticker = rep("TEST", 2),
    observation_date = rep(as.Date("2025-01-10"), 2),
    expiration = as.Date(c("2025-04-10", "2025-07-10")),
    days_to_expiration = c(90, 181),
    atm_iv = c(0.26, 0.24),
    atm_iv_call = c(0.25, 0.23),
    atm_iv_put = c(0.27, 0.25),
    atm_strike = rep(100, 2),
    spot_price = rep(100, 2)
  )

  result <- interpolate_iv_to_standard_tenors(term_structure)

  # 30d and 60d are below range -> NA

  expect_true(is.na(result$iv[result$tenor_days == 30]))
  expect_true(is.na(result$iv[result$tenor_days == 60]))
  # 90d and 180d are within range
  expect_equal(result$iv[result$tenor_days == 90], 0.26)
  expect_false(is.na(result$iv[result$tenor_days == 180]))
  # 365d is above range -> NA
  expect_true(is.na(result$iv[result$tenor_days == 365]))
})

test_that("interpolate_iv_to_standard_tenors handles single data point", {
  term_structure <- tibble::tibble(
    ticker = "TEST",
    observation_date = as.Date("2025-01-10"),
    expiration = as.Date("2025-04-10"),
    days_to_expiration = 90,
    atm_iv = 0.26,
    atm_iv_call = 0.25,
    atm_iv_put = 0.27,
    atm_strike = 100,
    spot_price = 100
  )

  result <- interpolate_iv_to_standard_tenors(term_structure)

  # Only exact match at 90d should have value
  expect_equal(result$iv[result$tenor_days == 90], 0.26)
  expect_true(is.na(result$iv[result$tenor_days == 30]))
  expect_true(is.na(result$iv[result$tenor_days == 365]))
})

test_that("interpolate_iv_to_standard_tenors returns empty for empty input", {
  term_structure <- tibble::tibble(
    ticker = character(),
    observation_date = as.Date(character()),
    expiration = as.Date(character()),
    days_to_expiration = numeric(),
    atm_iv = numeric(),
    atm_iv_call = numeric(),
    atm_iv_put = numeric(),
    atm_strike = numeric(),
    spot_price = numeric()
  )

  result <- interpolate_iv_to_standard_tenors(term_structure)

  expect_equal(nrow(result), 0)
  expect_equal(names(result), c("ticker", "observation_date", "tenor_days", "iv"))
})

test_that("interpolate_iv_to_standard_tenors accepts custom tenors", {
  term_structure <- tibble::tibble(
    ticker = rep("TEST", 2),
    observation_date = rep(as.Date("2025-01-10"), 2),
    expiration = as.Date(c("2025-02-09", "2025-04-10")),
    days_to_expiration = c(30, 90),
    atm_iv = c(0.30, 0.26),
    atm_iv_call = c(0.29, 0.25),
    atm_iv_put = c(0.31, 0.27),
    atm_strike = rep(100, 2),
    spot_price = rep(100, 2)
  )

  result <- interpolate_iv_to_standard_tenors(term_structure, tenors = c(45, 75))

  expect_equal(nrow(result), 2)
  expect_equal(result$tenor_days, c(45, 75))
  # Both should be interpolated between 30d and 90d
  expect_false(is.na(result$iv[1]))
  expect_false(is.na(result$iv[2]))
})
