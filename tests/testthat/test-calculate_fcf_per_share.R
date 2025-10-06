test_that("calculate_fcf_per_share handles valid inputs", {
  operating_cf <- c(10.5, 20.3, 15.7)
  capex <- c(-2.5, -3.1, -4.2)
  
  result <- calculate_fcf_per_share(operating_cf, capex)
  expected <- c(13.0, 23.4, 19.9)
  
  expect_equal(result, expected)
})

test_that("calculate_fcf_per_share handles NA values correctly", {
  # NA in operating_cf_ps
  result1 <- calculate_fcf_per_share(c(NA, 10), c(-2, -2))
  expect_equal(result1, c(NA_real_, 12))
  
  # NA in capex_ps
  result2 <- calculate_fcf_per_share(c(10, 10), c(NA, -2))
  expect_equal(result2, c(NA_real_, 12))
  
  # NA in both
  result3 <- calculate_fcf_per_share(c(NA, 10), c(NA, -2))
  expect_equal(result3, c(NA_real_, 12))
})

test_that("calculate_fcf_per_share handles edge cases", {
  # Zero values
  result1 <- calculate_fcf_per_share(c(0, 10), c(0, -5))
  expect_equal(result1, c(0, 15))
  
  # Negative operating cash flow
  result2 <- calculate_fcf_per_share(c(-5), c(-2))
  expect_equal(result2, c(-3))
  
  # Positive capex (unusual but valid)
  result3 <- calculate_fcf_per_share(c(10), c(2))
  expect_equal(result3, c(8))
})

test_that("calculate_fcf_per_share validates input types", {
  expect_error(
    calculate_fcf_per_share("not_numeric", c(-2)),
    "^calculate_fcf_per_share\\(\\): \\[operating_cf_ps\\] must be numeric, not character$"
  )
  
  expect_error(
    calculate_fcf_per_share(c(10), "not_numeric"),
    "^calculate_fcf_per_share\\(\\): \\[capex_ps\\] must be numeric, not character$"
  )
  
  expect_error(
    calculate_fcf_per_share(list(10), c(-2)),
    "^calculate_fcf_per_share\\(\\): \\[operating_cf_ps\\] must be numeric, not list$"
  )
})

test_that("calculate_fcf_per_share handles empty vectors", {
  result <- calculate_fcf_per_share(numeric(0), numeric(0))
  expect_equal(result, numeric(0))
  expect_length(result, 0)
})
