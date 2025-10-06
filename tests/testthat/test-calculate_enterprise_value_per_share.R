test_that("calculate_enterprise_value_per_share handles valid inputs", {
  price <- c(100, 150, 200)
  debt <- c(10, 15, 20)
  leases <- c(5, 7, 10)
  cash <- c(20, 25, 30)
  lt_inv <- c(10, 12, 15)
  
  result <- calculate_enterprise_value_per_share(price, debt, leases, cash, lt_inv)
  
  # Price + Debt + Leases - Cash - LT Investments
  # 100 + 10 + 5 - 20 - 10 = 85
  # 150 + 15 + 7 - 25 - 12 = 135
  # 200 + 20 + 10 - 30 - 15 = 185
  expected <- c(85, 135, 185)
  
  expect_equal(result, expected)
})

test_that("calculate_enterprise_value_per_share handles NA values with coalesce", {
  # NA debt coalesced to 0
  result1 <- calculate_enterprise_value_per_share(c(100), NA_real_, c(5), c(20), c(10))
  expected1 <- 100 + 0 + 5 - 20 - 10
  expect_equal(result1, expected1)
  
  # NA leases coalesced to 0
  result2 <- calculate_enterprise_value_per_share(c(100), c(10), NA_real_, c(20), c(10))
  expected2 <- 100 + 10 + 0 - 20 - 10
  expect_equal(result2, expected2)
  
  # NA cash coalesced to 0
  result3 <- calculate_enterprise_value_per_share(c(100), c(10), c(5), NA_real_, c(10))
  expected3 <- 100 + 10 + 5 - 0 - 10
  expect_equal(result3, expected3)
  
  # NA lt_investments coalesced to 0
  result4 <- calculate_enterprise_value_per_share(c(100), c(10), c(5), c(20), NA_real_)
  expected4 <- 100 + 10 + 5 - 20 - 0
  expect_equal(result4, expected4)
})

test_that("calculate_enterprise_value_per_share handles edge cases", {
  # All zeros except price
  result1 <- calculate_enterprise_value_per_share(c(100), c(0), c(0), c(0), c(0))
  expect_equal(result1, 100)
  
  # High debt increases EV
  result2 <- calculate_enterprise_value_per_share(c(100), c(50), c(0), c(0), c(0))
  expect_equal(result2, 150)
  
  # High cash decreases EV
  result3 <- calculate_enterprise_value_per_share(c(100), c(0), c(0), c(60), c(0))
  expect_equal(result3, 40)
  
  # Negative EV possible (cash-rich company)
  result4 <- calculate_enterprise_value_per_share(c(50), c(0), c(0), c(80), c(20))
  expect_equal(result4, -50)
})

test_that("calculate_enterprise_value_per_share handles multiple observations", {
  # Test with vectors of different scenarios
  price <- c(100, 50, 200)
  debt <- c(20, 10, 30)
  leases <- c(5, 2, 8)
  cash <- c(10, 5, 15)
  lt_inv <- c(5, 3, 10)
  
  result <- calculate_enterprise_value_per_share(price, debt, leases, cash, lt_inv)
  
  expected <- c(
    100 + 20 + 5 - 10 - 5,   # 110
    50 + 10 + 2 - 5 - 3,      # 54
    200 + 30 + 8 - 15 - 10    # 213
  )
  
  expect_equal(result, expected)
})

test_that("calculate_enterprise_value_per_share validates input types", {
  expect_error(
    calculate_enterprise_value_per_share("not_numeric", c(10), c(5), c(20), c(10)),
    "^calculate_enterprise_value_per_share\\(\\): \\[price\\] must be numeric, not character$"
  )
  
  expect_error(
    calculate_enterprise_value_per_share(c(100), "not_numeric", c(5), c(20), c(10)),
    "^calculate_enterprise_value_per_share\\(\\): \\[debt_total_ps\\] must be numeric, not character$"
  )
  
  expect_error(
    calculate_enterprise_value_per_share(c(100), c(10), "not_numeric", c(20), c(10)),
    "^calculate_enterprise_value_per_share\\(\\): \\[lease_obligations_ps\\] must be numeric, not character$"
  )
  
  expect_error(
    calculate_enterprise_value_per_share(c(100), c(10), c(5), "not_numeric", c(10)),
    "^calculate_enterprise_value_per_share\\(\\): \\[cash_st_investments_ps\\] must be numeric, not character$"
  )
  
  expect_error(
    calculate_enterprise_value_per_share(c(100), c(10), c(5), c(20), "not_numeric"),
    "^calculate_enterprise_value_per_share\\(\\): \\[lt_investments_ps\\] must be numeric, not character$"
  )
})

test_that("calculate_enterprise_value_per_share handles empty vectors", {
  result <- calculate_enterprise_value_per_share(
    numeric(0), 
    numeric(0), 
    numeric(0), 
    numeric(0), 
    numeric(0)
  )
  expect_equal(result, numeric(0))
  expect_length(result, 0)
})
