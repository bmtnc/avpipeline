#' Calculate Enterprise Value Per Share
#'
#' Calculates enterprise value per share by adjusting market price for debt,
#' lease obligations, and liquid assets.
#' Formula: Price + Total Debt + Lease Obligations - Cash - Long-term Investments
#'
#' @param price numeric: Market price per share (typically adjusted close)
#' @param debt_total_ps numeric: Total debt per share
#' @param lease_obligations_ps numeric: Capital lease obligations per share
#' @param cash_st_investments_ps numeric: Cash and short-term investments per share
#' @param lt_investments_ps numeric: Long-term investments per share
#' @return numeric: Enterprise value per share vector
#' @keywords internal
calculate_enterprise_value_per_share <- function(
  price,
  debt_total_ps,
  lease_obligations_ps,
  cash_st_investments_ps,
  lt_investments_ps
) {
  # Input validation
  if (!is.numeric(price)) {
    stop(paste0(
      "calculate_enterprise_value_per_share(): [price] must be numeric, not ",
      class(price)[1]
    ))
  }

  if (!is.numeric(debt_total_ps)) {
    stop(paste0(
      "calculate_enterprise_value_per_share(): [debt_total_ps] must be numeric, not ",
      class(debt_total_ps)[1]
    ))
  }

  if (!is.numeric(lease_obligations_ps)) {
    stop(paste0(
      "calculate_enterprise_value_per_share(): [lease_obligations_ps] must be numeric, not ",
      class(lease_obligations_ps)[1]
    ))
  }

  if (!is.numeric(cash_st_investments_ps)) {
    stop(paste0(
      "calculate_enterprise_value_per_share(): [cash_st_investments_ps] must be numeric, not ",
      class(cash_st_investments_ps)[1]
    ))
  }

  if (!is.numeric(lt_investments_ps)) {
    stop(paste0(
      "calculate_enterprise_value_per_share(): [lt_investments_ps] must be numeric, not ",
      class(lt_investments_ps)[1]
    ))
  }

  # Calculate enterprise value
  price +
    dplyr::coalesce(debt_total_ps, 0) +
    dplyr::coalesce(lease_obligations_ps, 0) -
    dplyr::coalesce(cash_st_investments_ps, 0) -
    dplyr::coalesce(lt_investments_ps, 0)
}
