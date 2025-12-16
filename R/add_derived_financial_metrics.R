#' Add Derived Financial Metrics
#'
#' Orchestrates calculation of derived financial metrics by composing
#' individual calculation functions. Adds FCF, NOPAT, enterprise value,
#' invested capital, and data quality flags to the input data.
#'
#' @param data tibble: Data frame with per-share financial metrics
#' @return tibble: Input data with derived metrics added as new columns
#' @keywords internal
add_derived_financial_metrics <- function(data) {
  # Input validation
  if (!is.data.frame(data)) {
    stop(paste0(
      "add_derived_financial_metrics(): [data] must be a data.frame, not ",
      class(data)[1]
    ))
  }

  # Define required columns
  required_cols <- c(
    "operatingCashflow_ttm_per_share",
    "capitalExpenditures_ttm_per_share",
    "ebit_ttm_per_share",
    "depreciationAndAmortization_ttm_per_share",
    "depreciation_ttm_per_share",
    "adjusted_close",
    "shortLongTermDebtTotal_per_share",
    "capitalLeaseObligations_per_share",
    "cashAndShortTermInvestments_per_share",
    "longTermInvestments_per_share",
    "totalShareholderEquity_per_share",
    "totalRevenue_ttm_per_share",
    "totalAssets_per_share"
  )

  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop(paste0(
      "add_derived_financial_metrics(): [data] is missing required columns: ",
      paste(missing_cols, collapse = ", ")
    ))
  }

  # Calculate derived metrics
  data %>%
    dplyr::mutate(
      fcf_ttm_per_share = calculate_fcf_per_share(
        operatingCashflow_ttm_per_share,
        capitalExpenditures_ttm_per_share
      ),
      nopat_ttm_per_share = calculate_nopat_per_share(
        ebit_ttm_per_share,
        depreciationAndAmortization_ttm_per_share,
        depreciation_ttm_per_share
      ),
      enterprise_value_per_share = calculate_enterprise_value_per_share(
        adjusted_close,
        shortLongTermDebtTotal_per_share,
        capitalLeaseObligations_per_share,
        cashAndShortTermInvestments_per_share,
        longTermInvestments_per_share
      ),
      invested_capital_per_share = calculate_invested_capital_per_share(
        shortLongTermDebtTotal_per_share,
        capitalLeaseObligations_per_share,
        totalShareholderEquity_per_share
      ),
      has_complete_financial_data = !is.na(totalRevenue_ttm_per_share) &
        !is.na(totalAssets_per_share) &
        !is.na(operatingCashflow_ttm_per_share)
    )
}
