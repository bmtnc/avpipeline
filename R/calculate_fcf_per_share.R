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
  if (!is.numeric(operating_cf_ps)) {
    stop(paste0(
      "calculate_fcf_per_share(): [operating_cf_ps] must be numeric, not ",
      class(operating_cf_ps)[1]
    ))
  }
  
  if (!is.numeric(capex_ps)) {
    stop(paste0(
      "calculate_fcf_per_share(): [capex_ps] must be numeric, not ",
      class(capex_ps)[1]
    ))
  }
  
  dplyr::if_else(
    !is.na(operating_cf_ps) & !is.na(capex_ps),
    operating_cf_ps - capex_ps,
    NA_real_
  )
}
