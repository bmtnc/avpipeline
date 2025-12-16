#' Calculate Free Cash Flow Per Share
#'
#' Calculates free cash flow per share by subtracting capital expenditures
#' from operating cash flow. Both inputs are assumed to be per-share values.
#'
#' @param operating_cf_ps numeric: Operating cash flow per share (TTM)
#' @param capex_ps numeric: Capital expenditures per share (TTM, typically negative)
#' @return numeric: Free cash flow per share vector
#' @keywords internal
calculate_fcf_per_share <- function(operating_cf_ps, capex_ps) {
  # Input validation
  validate_numeric_vector(operating_cf_ps, allow_empty = TRUE, name = "operating_cf_ps")
  validate_numeric_vector(capex_ps, allow_empty = TRUE, name = "capex_ps")

  dplyr::if_else(
    !is.na(operating_cf_ps) & !is.na(capex_ps),
    operating_cf_ps - capex_ps,
    NA_real_
  )
}
