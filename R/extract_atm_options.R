#' Extract At-The-Money Options from an Option Chain
#'
#' @param options_chain Tibble of options for a single observation date
#' @param spot_price Numeric. Current stock price
#' @param moneyness_threshold Numeric. Maximum abs(strike/spot - 1) to consider ATM
#'
#' @return Tibble with one row per (expiration, type) for the closest-to-ATM options
#' @keywords internal
extract_atm_options <- function(options_chain, spot_price, moneyness_threshold = 0.05) {
  if (nrow(options_chain) == 0 || is.na(spot_price) || spot_price <= 0) {
    return(options_chain[0, ])
  }

  options_chain %>%
    dplyr::mutate(
      moneyness = abs(strike / spot_price - 1)
    ) %>%
    dplyr::filter(moneyness <= moneyness_threshold) %>%
    dplyr::group_by(expiration, type) %>%
    dplyr::slice_min(moneyness, n = 1, with_ties = FALSE) %>%
    dplyr::ungroup() %>%
    dplyr::select(-moneyness)
}
