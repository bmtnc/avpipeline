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
  validate_numeric_vector(price, allow_empty = TRUE, name = "price")
  validate_numeric_vector(debt_total_ps, allow_empty = TRUE, name = "debt_total_ps")
  validate_numeric_vector(lease_obligations_ps, allow_empty = TRUE, name = "lease_obligations_ps")
  validate_numeric_vector(cash_st_investments_ps, allow_empty = TRUE, name = "cash_st_investments_ps")
  validate_numeric_vector(lt_investments_ps, allow_empty = TRUE, name = "lt_investments_ps")

  # Calculate enterprise value
  price +
    dplyr::coalesce(debt_total_ps, 0) +
    dplyr::coalesce(lease_obligations_ps, 0) -
    dplyr::coalesce(cash_st_investments_ps, 0) -
    dplyr::coalesce(lt_investments_ps, 0)
}
