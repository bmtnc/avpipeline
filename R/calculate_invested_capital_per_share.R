#' Calculate Invested Capital Per Share
#'
#' Calculates total invested capital per share by summing debt and equity components.
#' Formula: Total Debt + Lease Obligations + Total Shareholder Equity
#'
#' @param debt_total_ps numeric: Total debt per share
#' @param lease_obligations_ps numeric: Capital lease obligations per share
#' @param equity_ps numeric: Total shareholder equity per share
#' @return numeric: Invested capital per share vector
#' @keywords internal
calculate_invested_capital_per_share <- function(debt_total_ps, lease_obligations_ps, equity_ps) {
  # Input validation
  if (!is.numeric(debt_total_ps)) {
    stop(paste0(
      "calculate_invested_capital_per_share(): [debt_total_ps] must be numeric, not ",
      class(debt_total_ps)[1]
    ))
  }
  
  if (!is.numeric(lease_obligations_ps)) {
    stop(paste0(
      "calculate_invested_capital_per_share(): [lease_obligations_ps] must be numeric, not ",
      class(lease_obligations_ps)[1]
    ))
  }
  
  if (!is.numeric(equity_ps)) {
    stop(paste0(
      "calculate_invested_capital_per_share(): [equity_ps] must be numeric, not ",
      class(equity_ps)[1]
    ))
  }
  
  # Calculate invested capital
  dplyr::coalesce(debt_total_ps, 0) +
    dplyr::coalesce(lease_obligations_ps, 0) +
    dplyr::coalesce(equity_ps, 0)
}
