make_statement <- function(dates) {
  tibble::tibble(fiscalDateEnding = as.Date(dates), totalRevenue = 1)
}

test_that("returns FALSE when all statements match earnings max fiscal date", {
  dates <- c("2026-03-31", "2026-06-30")
  result <- detect_statement_lag(
    income_statement = make_statement(dates),
    balance_sheet = make_statement(dates),
    cash_flow = make_statement(dates),
    earnings = make_statement(dates)
  )
  expect_false(result)
})

test_that("returns TRUE when one statement lags earnings", {
  current <- c("2026-03-31", "2026-06-30")
  lagged <- c("2025-12-31", "2026-03-31")
  result <- detect_statement_lag(
    income_statement = make_statement(current),
    balance_sheet = make_statement(current),
    cash_flow = make_statement(lagged),
    earnings = make_statement(current)
  )
  expect_true(result)
})

test_that("returns TRUE when all statements lag earnings", {
  result <- detect_statement_lag(
    income_statement = make_statement("2026-03-31"),
    balance_sheet = make_statement("2026-03-31"),
    cash_flow = make_statement("2026-03-31"),
    earnings = make_statement(c("2026-03-31", "2026-06-30"))
  )
  expect_true(result)
})

test_that("returns FALSE when earnings is NULL or empty", {
  statements <- make_statement("2026-03-31")
  expect_false(detect_statement_lag(statements, statements, statements, NULL))
  expect_false(detect_statement_lag(
    statements,
    statements,
    statements,
    make_statement(character(0))
  ))
})

test_that("returns TRUE when a statement is NULL or empty but earnings has data", {
  statements <- make_statement("2026-06-30")
  earnings <- make_statement("2026-06-30")
  expect_true(detect_statement_lag(NULL, statements, statements, earnings))
  expect_true(detect_statement_lag(
    make_statement(character(0)),
    statements,
    statements,
    earnings
  ))
})

test_that("returns FALSE when statements are ahead of earnings", {
  result <- detect_statement_lag(
    income_statement = make_statement("2026-06-30"),
    balance_sheet = make_statement("2026-06-30"),
    cash_flow = make_statement("2026-06-30"),
    earnings = make_statement("2026-03-31")
  )
  expect_false(result)
})

test_that("ignores NA fiscal dates", {
  with_na <- tibble::tibble(
    fiscalDateEnding = as.Date(c("2026-06-30", NA)),
    totalRevenue = 1
  )
  result <- detect_statement_lag(
    income_statement = with_na,
    balance_sheet = with_na,
    cash_flow = with_na,
    earnings = with_na
  )
  expect_false(result)
})
