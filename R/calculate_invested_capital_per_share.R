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
calculate_invested_capital_per_share <- function(
  debt_total_ps,
  lease_obligations_ps,
  equity_ps
) {
  validate_numeric_vector(debt_total_ps, allow_empty = TRUE, name = "debt_total_ps")
  validate_numeric_vector(lease_obligations_ps, allow_empty = TRUE, name = "lease_obligations_ps")
  validate_numeric_vector(equity_ps, allow_empty = TRUE, name = "equity_ps")

  # Calculate invested capital
  dplyr::coalesce(debt_total_ps, 0) +
    dplyr::coalesce(lease_obligations_ps, 0) +
    dplyr::coalesce(equity_ps, 0)
}
