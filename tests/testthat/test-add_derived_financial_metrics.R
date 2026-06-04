test_that("add_derived_financial_metrics adds all derived metrics", {
  # nolint start
  # fmt: skip
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~operatingCashflow_ttm_per_share, ~capitalExpenditures_ttm_per_share, ~ebit_ttm_per_share, ~depreciationAndAmortization_ttm_per_share, ~depreciation_ttm_per_share, ~adjusted_close, ~shortLongTermDebtTotal_per_share, ~capitalLeaseObligations_per_share, ~cashAndShortTermInvestments_per_share, ~longTermInvestments_per_share, ~totalShareholderEquity_per_share, ~totalRevenue_ttm_per_share, ~totalAssets_per_share,
    "AAPL",  "2023-01-01", 10.0,                             -2.0,                               100.0,               20.0,                                       15.0,                        150.0,           10.0,                              5.0,                                20.0,                                   10.0,                           200.0,                             50.0,                        300.0,
    "AAPL",  "2023-01-02", 10.0,                             -2.0,                               100.0,               20.0,                                       15.0,                        150.0,           10.0,                              5.0,                                20.0,                                   10.0,                           200.0,                             50.0,                        300.0
  ) %>%
    dplyr::mutate(date = as.Date(date))
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
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~operatingCashflow_ttm_per_share, ~capitalExpenditures_ttm_per_share, ~ebit_ttm_per_share, ~depreciationAndAmortization_ttm_per_share, ~depreciation_ttm_per_share, ~adjusted_close, ~shortLongTermDebtTotal_per_share, ~capitalLeaseObligations_per_share, ~cashAndShortTermInvestments_per_share, ~longTermInvestments_per_share, ~totalShareholderEquity_per_share, ~totalRevenue_ttm_per_share, ~totalAssets_per_share,
    "AAPL",  "2023-01-01", 10.0,                             -2.0,                               100.0,               20.0,                                       15.0,                        150.0,           10.0,                              5.0,                                20.0,                                   10.0,                           200.0,                             50.0,                        300.0,
    "AAPL",  "2023-01-02", NA_real_,                         -2.0,                               100.0,               20.0,                                       15.0,                        150.0,           10.0,                              5.0,                                20.0,                                   10.0,                           200.0,                             NA_real_,                    300.0
  ) %>%
    dplyr::mutate(date = as.Date(date))
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
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~custom_column, ~operatingCashflow_ttm_per_share, ~capitalExpenditures_ttm_per_share, ~ebit_ttm_per_share, ~depreciationAndAmortization_ttm_per_share, ~depreciation_ttm_per_share, ~adjusted_close, ~shortLongTermDebtTotal_per_share, ~capitalLeaseObligations_per_share, ~cashAndShortTermInvestments_per_share, ~longTermInvestments_per_share, ~totalShareholderEquity_per_share, ~totalRevenue_ttm_per_share, ~totalAssets_per_share,
    "AAPL",  "2023-01-01", "test",         10.0,                             -2.0,                               100.0,               20.0,                                       15.0,                        150.0,           10.0,                              5.0,                                20.0,                                   10.0,                           200.0,                             50.0,                        300.0
  ) %>%
    dplyr::mutate(date = as.Date(date))
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
  input_data <- tibble::tribble(
    ~ticker, ~date,        ~operatingCashflow_ttm_per_share, ~capitalExpenditures_ttm_per_share, ~ebit_ttm_per_share, ~depreciationAndAmortization_ttm_per_share, ~depreciation_ttm_per_share, ~adjusted_close, ~shortLongTermDebtTotal_per_share, ~capitalLeaseObligations_per_share, ~cashAndShortTermInvestments_per_share, ~longTermInvestments_per_share, ~totalShareholderEquity_per_share, ~totalRevenue_ttm_per_share, ~totalAssets_per_share,
    "AAPL",  "2023-01-01", NA_real_,                         -2.0,                               NA_real_,            20.0,                                       15.0,                        150.0,           NA_real_,                          5.0,                                20.0,                                   10.0,                           200.0,                             50.0,                        300.0
  ) %>%
    dplyr::mutate(date = as.Date(date))
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
