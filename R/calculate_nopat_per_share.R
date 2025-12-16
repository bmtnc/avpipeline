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
  if (!is.numeric(ebit_ps)) {
    stop(paste0(
      "calculate_nopat_per_share(): [ebit_ps] must be numeric, not ",
      class(ebit_ps)[1]
    ))
  }
  if (!is.numeric(dep_amort_ps)) {
    stop(paste0(
      "calculate_nopat_per_share(): [dep_amort_ps] must be numeric, not ",
      class(dep_amort_ps)[1]
    ))
  }
  if (!is.numeric(depreciation_ps)) {
    stop(paste0(
      "calculate_nopat_per_share(): [depreciation_ps] must be numeric, not ",
      class(depreciation_ps)[1]
    ))
  }
  if (!is.numeric(tax_rate) || length(tax_rate) != 1) {
    stop(paste0(
      "calculate_nopat_per_share(): [tax_rate] must be a numeric scalar, not ",
      class(tax_rate)[1],
      " of length ",
      length(tax_rate)
    ))
  }
  if (tax_rate < 0 || tax_rate > 1) {
    stop(paste0(
      "calculate_nopat_per_share(): [tax_rate] must be between 0 and 1, not ",
      tax_rate
    ))
  }

  # Calculate amortization (D&A minus depreciation)
  amortization_ps <- dplyr::coalesce(dep_amort_ps, 0) -
    dplyr::coalesce(depreciation_ps, 0)

  # Apply NOPAT formula
  dplyr::case_when(
    is.na(ebit_ps) ~ NA_real_,
    TRUE ~ (ebit_ps + pmax(amortization_ps, 0)) * (1 - tax_rate)
  )
}
