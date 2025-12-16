test_that("add_derived_financial_metrics adds all derived metrics", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tibble(
    ticker                                  = c("AAPL",  "AAPL"),
    date                                    = as.Date(c("2023-01-01", "2023-01-02")),
    operatingCashflow_ttm_per_share         = c(10.0,    10.0),
    capitalExpenditures_ttm_per_share       = c(-2.0,    -2.0),
    ebit_ttm_per_share                      = c(100.0,   100.0),
    depreciationAndAmortization_ttm_per_share = c(20.0,  20.0),
    depreciation_ttm_per_share              = c(15.0,    15.0),
    adjusted_close                          = c(150.0,   150.0),
    shortLongTermDebtTotal_per_share        = c(10.0,    10.0),
    capitalLeaseObligations_per_share       = c(5.0,     5.0),
    cashAndShortTermInvestments_per_share   = c(20.0,    20.0),
    longTermInvestments_per_share           = c(10.0,    10.0),
    totalShareholderEquity_per_share        = c(200.0,   200.0),
    totalRevenue_ttm_per_share              = c(50.0,    50.0),
    totalAssets_per_share                   = c(300.0,   300.0)
  )
  # nolint end
  
  result <- add_derived_financial_metrics(input_data)
  
  # Check that new columns exist
  expect_true("fcf_ttm_per_share" %in% names(result))
  expect_true("nopat_ttm_per_share" %in% names(result))
  expect_true("enterprise_value_per_share" %in% names(result))
  expect_true("invested_capital_per_share" %in% names(result))
  expect_true("has_complete_financial_data" %in% names(result))
  
  # Check FCF calculation
  expect_equal(result$fcf_ttm_per_share, c(12.0, 12.0))
  
  # Check NOPAT calculation (EBIT + Amortization) * (1 - 0.2375)
  # Amortization = 20 - 15 = 5
  # (100 + 5) * 0.7625 = 80.0625
  expect_equal(result$nopat_ttm_per_share, c(80.0625, 80.0625))
  
  # Check enterprise value calculation
  # 150 + 10 + 5 - 20 - 10 = 135
  expect_equal(result$enterprise_value_per_share, c(135, 135))
  
  # Check invested capital calculation
  # 10 + 5 + 200 = 215
  expect_equal(result$invested_capital_per_share, c(215, 215))
  
  # Check data quality flag
  expect_equal(result$has_complete_financial_data, c(TRUE, TRUE))
})

test_that("add_derived_financial_metrics handles missing financial data flag", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tibble(
    ticker                                  = c("AAPL",  "AAPL"),
    date                                    = as.Date(c("2023-01-01", "2023-01-02")),
    operatingCashflow_ttm_per_share         = c(10.0,    NA_real_),
    capitalExpenditures_ttm_per_share       = c(-2.0,    -2.0),
    ebit_ttm_per_share                      = c(100.0,   100.0),
    depreciationAndAmortization_ttm_per_share = c(20.0,  20.0),
    depreciation_ttm_per_share              = c(15.0,    15.0),
    adjusted_close                          = c(150.0,   150.0),
    shortLongTermDebtTotal_per_share        = c(10.0,    10.0),
    capitalLeaseObligations_per_share       = c(5.0,     5.0),
    cashAndShortTermInvestments_per_share   = c(20.0,    20.0),
    longTermInvestments_per_share           = c(10.0,    10.0),
    totalShareholderEquity_per_share        = c(200.0,   200.0),
    totalRevenue_ttm_per_share              = c(50.0,    NA_real_),
    totalAssets_per_share                   = c(300.0,   300.0)
  )
  # nolint end
  
  result <- add_derived_financial_metrics(input_data)
  
  # First row has complete data
  expect_equal(result$has_complete_financial_data[1], TRUE)
  
  # Second row missing both revenue and operating cashflow
  expect_equal(result$has_complete_financial_data[2], FALSE)
})

test_that("add_derived_financial_metrics preserves original columns", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tibble(
    ticker                                  = c("AAPL"),
    date                                    = as.Date("2023-01-01"),
    custom_column                           = c("test"),
    operatingCashflow_ttm_per_share         = c(10.0),
    capitalExpenditures_ttm_per_share       = c(-2.0),
    ebit_ttm_per_share                      = c(100.0),
    depreciationAndAmortization_ttm_per_share = c(20.0),
    depreciation_ttm_per_share              = c(15.0),
    adjusted_close                          = c(150.0),
    shortLongTermDebtTotal_per_share        = c(10.0),
    capitalLeaseObligations_per_share       = c(5.0),
    cashAndShortTermInvestments_per_share   = c(20.0),
    longTermInvestments_per_share           = c(10.0),
    totalShareholderEquity_per_share        = c(200.0),
    totalRevenue_ttm_per_share              = c(50.0),
    totalAssets_per_share                   = c(300.0)
  )
  # nolint end
  
  result <- add_derived_financial_metrics(input_data)
  
  # Original columns should still exist
  expect_true("ticker" %in% names(result))
  expect_true("date" %in% names(result))
  expect_true("custom_column" %in% names(result))
  expect_equal(result$custom_column, "test")
})

test_that("add_derived_financial_metrics handles NA values in calculations", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tibble(
    ticker                                  = c("AAPL"),
    date                                    = as.Date("2023-01-01"),
    operatingCashflow_ttm_per_share         = c(NA_real_),
    capitalExpenditures_ttm_per_share       = c(-2.0),
    ebit_ttm_per_share                      = c(NA_real_),
    depreciationAndAmortization_ttm_per_share = c(20.0),
    depreciation_ttm_per_share              = c(15.0),
    adjusted_close                          = c(150.0),
    shortLongTermDebtTotal_per_share        = c(NA_real_),
    capitalLeaseObligations_per_share       = c(5.0),
    cashAndShortTermInvestments_per_share   = c(20.0),
    longTermInvestments_per_share           = c(10.0),
    totalShareholderEquity_per_share        = c(200.0),
    totalRevenue_ttm_per_share              = c(50.0),
    totalAssets_per_share                   = c(300.0)
  )
  # nolint end
  
  result <- add_derived_financial_metrics(input_data)
  
  # FCF should be NA (operating cashflow is NA)
  expect_true(is.na(result$fcf_ttm_per_share))
  
  # NOPAT should be NA (EBIT is NA)
  expect_true(is.na(result$nopat_ttm_per_share))
  
  # Enterprise value should use coalesce for NA debt (treated as 0)
  # 150 + 0 + 5 - 20 - 10 = 125
  expect_equal(result$enterprise_value_per_share, 125)
  
  # Invested capital should use coalesce for NA debt
  # 0 + 5 + 200 = 205
  expect_equal(result$invested_capital_per_share, 205)
})
