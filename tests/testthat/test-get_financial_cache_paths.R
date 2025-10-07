test_that("get_financial_cache_paths returns correct structure", {
  paths <- get_financial_cache_paths()
  
  expect_type(paths, "list")
  expect_named(paths, c("balance_sheet", "cash_flow", "income_statement", "earnings"))
})

test_that("get_financial_cache_paths returns correct paths", {
  paths <- get_financial_cache_paths()
  
  expect_equal(paths$balance_sheet, "cache/balance_sheet_artifact.csv")
  expect_equal(paths$cash_flow, "cache/cash_flow_artifact.csv")
  expect_equal(paths$income_statement, "cache/income_statement_artifact.csv")
  expect_equal(paths$earnings, "cache/earnings_artifact.csv")
})

test_that("get_financial_cache_paths returns character paths", {
  paths <- get_financial_cache_paths()
  
  expect_type(paths$balance_sheet, "character")
  expect_type(paths$cash_flow, "character")
  expect_type(paths$income_statement, "character")
  expect_type(paths$earnings, "character")
})
