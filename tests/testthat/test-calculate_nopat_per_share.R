test_that("calculate_nopat_per_share handles valid inputs", {
  ebit <- c(100, 200, 150)
  dep_amort <- c(20, 30, 25)
  depreciation <- c(15, 20, 18)
  
  result <- calculate_nopat_per_share(ebit, dep_amort, depreciation)
  
  # (EBIT + max(D&A - Depreciation, 0)) * (1 - 0.2375)
  # (100 + max(5, 0)) * 0.7625 = 80.0625
  # (200 + max(10, 0)) * 0.7625 = 160.125
  # (150 + max(7, 0)) * 0.7625 = 119.7125
  expected <- c(80.0625, 160.125, 119.7125)
  
  expect_equal(result, expected)
})

test_that("calculate_nopat_per_share uses custom tax rate", {
  ebit <- c(100)
  dep_amort <- c(20)
  depreciation <- c(15)
  
  result <- calculate_nopat_per_share(ebit, dep_amort, depreciation, tax_rate = 0.30)
  
  # (100 + 5) * (1 - 0.30) = 73.5
  expected <- 73.5
  
  expect_equal(result, expected)
})

test_that("calculate_nopat_per_share handles NA values correctly", {
  # NA in ebit_ps
  result1 <- calculate_nopat_per_share(c(NA, 100), c(20, 20), c(15, 15))
  expect_true(is.na(result1[1]))
  expect_false(is.na(result1[2]))
  
  # NA in dep_amort_ps (coalesced to 0)
  result2 <- calculate_nopat_per_share(c(100), NA_real_, c(15))
  expected2 <- 100 * (1 - 0.2375)
  expect_equal(result2, expected2)
  
  # NA in depreciation_ps (coalesced to 0)
  result3 <- calculate_nopat_per_share(c(100), c(20), NA_real_)
  expected3 <- (100 + 20) * (1 - 0.2375)
  expect_equal(result3, expected3)
})

test_that("calculate_nopat_per_share handles negative amortization", {
  # When D&A < Depreciation, amortization is negative, use 0 instead
  ebit <- c(100)
  dep_amort <- c(10)
  depreciation <- c(15)
  
  result <- calculate_nopat_per_share(ebit, dep_amort, depreciation)
  
  # Amortization = max(10 - 15, 0) = 0
  # (100 + 0) * (1 - 0.2375) = 76.25
  expected <- 76.25
  
  expect_equal(result, expected)
})

test_that("calculate_nopat_per_share handles edge cases", {
  # Zero EBIT
  result1 <- calculate_nopat_per_share(c(0), c(20), c(15))
  expected1 <- 5 * (1 - 0.2375)
  expect_equal(result1, expected1)
  
  # Negative EBIT
  result2 <- calculate_nopat_per_share(c(-50), c(20), c(15))
  expected2 <- (-50 + 5) * (1 - 0.2375)
  expect_equal(result2, expected2)
  
  # All zeros
  result3 <- calculate_nopat_per_share(c(0), c(0), c(0))
  expect_equal(result3, 0)
})

test_that("calculate_nopat_per_share validates input types", {
  expect_error(
    calculate_nopat_per_share("not_numeric", c(20), c(15)),
    "^ebit_ps must be a numeric vector\\. Received: character$"
  )

  expect_error(
    calculate_nopat_per_share(c(100), "not_numeric", c(15)),
    "^dep_amort_ps must be a numeric vector\\. Received: character$"
  )

  expect_error(
    calculate_nopat_per_share(c(100), c(20), "not_numeric"),
    "^depreciation_ps must be a numeric vector\\. Received: character$"
  )
})

test_that("calculate_nopat_per_share validates tax_rate parameter", {
  # Non-numeric tax_rate
  expect_error(
    calculate_nopat_per_share(c(100), c(20), c(15), tax_rate = "0.25"),
    "^tax_rate must be a numeric scalar \\(length 1\\)\\. Received: character of length 1$"
  )

  # Vector tax_rate
  expect_error(
    calculate_nopat_per_share(c(100), c(20), c(15), tax_rate = c(0.2, 0.3)),
    "^tax_rate must be a numeric scalar \\(length 1\\)\\. Received: numeric of length 2$"
  )

  # Tax rate out of range (negative)
  expect_error(
    calculate_nopat_per_share(c(100), c(20), c(15), tax_rate = -0.1),
    "^tax_rate must be >= 0\\. Received: -0\\.1$"
  )

  # Tax rate out of range (> 1)
  expect_error(
    calculate_nopat_per_share(c(100), c(20), c(15), tax_rate = 1.5),
    "^tax_rate must be <= 1\\. Received: 1\\.5$"
  )
})

test_that("calculate_nopat_per_share handles empty vectors", {
  result <- calculate_nopat_per_share(numeric(0), numeric(0), numeric(0))
  expect_equal(result, numeric(0))
  expect_length(result, 0)
})
