test_that("calculate_invested_capital_per_share handles valid inputs", {
  debt <- c(50, 75, 100)
  leases <- c(10, 15, 20)
  equity <- c(200, 250, 300)
  
  result <- calculate_invested_capital_per_share(debt, leases, equity)
  
  # Debt + Leases + Equity
  # 50 + 10 + 200 = 260
  # 75 + 15 + 250 = 340
  # 100 + 20 + 300 = 420
  expected <- c(260, 340, 420)
  
  expect_equal(result, expected)
})

test_that("calculate_invested_capital_per_share handles NA values with coalesce", {
  # NA debt coalesced to 0
  result1 <- calculate_invested_capital_per_share(NA_real_, c(10), c(200))
  expected1 <- 0 + 10 + 200
  expect_equal(result1, expected1)
  
  # NA leases coalesced to 0
  result2 <- calculate_invested_capital_per_share(c(50), NA_real_, c(200))
  expected2 <- 50 + 0 + 200
  expect_equal(result2, expected2)
  
  # NA equity coalesced to 0
  result3 <- calculate_invested_capital_per_share(c(50), c(10), NA_real_)
  expected3 <- 50 + 10 + 0
  expect_equal(result3, expected3)
  
  # All NA coalesced to 0
  result4 <- calculate_invested_capital_per_share(NA_real_, NA_real_, NA_real_)
  expect_equal(result4, 0)
})

test_that("calculate_invested_capital_per_share handles edge cases", {
  # All zeros
  result1 <- calculate_invested_capital_per_share(c(0), c(0), c(0))
  expect_equal(result1, 0)
  
  # High debt, no equity
  result2 <- calculate_invested_capital_per_share(c(100), c(20), c(0))
  expect_equal(result2, 120)
  
  # High equity, no debt
  result3 <- calculate_invested_capital_per_share(c(0), c(0), c(500))
  expect_equal(result3, 500)
  
  # Negative values (possible for negative equity)
  result4 <- calculate_invested_capital_per_share(c(50), c(10), c(-30))
  expect_equal(result4, 30)
})

test_that("calculate_invested_capital_per_share handles multiple observations", {
  debt <- c(50, 100, 25)
  leases <- c(10, 20, 5)
  equity <- c(200, 300, 150)
  
  result <- calculate_invested_capital_per_share(debt, leases, equity)
  
  expected <- c(
    50 + 10 + 200,    # 260
    100 + 20 + 300,   # 420
    25 + 5 + 150      # 180
  )
  
  expect_equal(result, expected)
})

test_that("calculate_invested_capital_per_share validates input types", {
  expect_error(
    calculate_invested_capital_per_share("not_numeric", c(10), c(200)),
    "^debt_total_ps must be a numeric vector\\. Received: character$"
  )

  expect_error(
    calculate_invested_capital_per_share(c(50), "not_numeric", c(200)),
    "^lease_obligations_ps must be a numeric vector\\. Received: character$"
  )

  expect_error(
    calculate_invested_capital_per_share(c(50), c(10), "not_numeric"),
    "^equity_ps must be a numeric vector\\. Received: character$"
  )

  expect_error(
    calculate_invested_capital_per_share(list(50), c(10), c(200)),
    "^debt_total_ps must be a numeric vector\\. Received: list$"
  )
})

test_that("calculate_invested_capital_per_share handles empty vectors", {
  result <- calculate_invested_capital_per_share(numeric(0), numeric(0), numeric(0))
  expect_equal(result, numeric(0))
  expect_length(result, 0)
})
