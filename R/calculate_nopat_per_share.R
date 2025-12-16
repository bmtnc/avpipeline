#' Calculate NOPAT Per Share
#'
#' Calculates Net Operating Profit After Tax (NOPAT) per share.
#' Formula: (EBIT + Amortization) × (1 - Tax Rate)
#' where Amortization = max(Depreciation & Amortization - Depreciation, 0)
#'
#' @param ebit_ps numeric: EBIT per share (TTM)
#' @param dep_amort_ps numeric: Depreciation and amortization per share (TTM)
#' @param depreciation_ps numeric: Depreciation per share (TTM)
#' @param tax_rate numeric: Corporate tax rate (default 0.2375 = 23.75%)
#' @return numeric: NOPAT per share vector
#' @keywords internal
calculate_nopat_per_share <- function(
  ebit_ps,
  dep_amort_ps,
  depreciation_ps,
  tax_rate = 0.2375
) {
  # Input validation
  validate_numeric_vector(ebit_ps, allow_empty = TRUE, name = "ebit_ps")
  validate_numeric_vector(dep_amort_ps, allow_empty = TRUE, name = "dep_amort_ps")
  validate_numeric_vector(depreciation_ps, allow_empty = TRUE, name = "depreciation_ps")
  validate_numeric_scalar(tax_rate, name = "tax_rate", gte = 0, lte = 1)

  # Calculate amortization (D&A minus depreciation)
  amortization_ps <- dplyr::coalesce(dep_amort_ps, 0) -
    dplyr::coalesce(depreciation_ps, 0)

  # Apply NOPAT formula
  dplyr::case_when(
    is.na(ebit_ps) ~ NA_real_,
    TRUE ~ (ebit_ps + pmax(amortization_ps, 0)) * (1 - tax_rate)
  )
}
