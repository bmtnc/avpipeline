#' Calculate Implied Volatility Term Structure for One Observation Date
#'
#' @param options_chain Tibble of options for a single observation date
#' @param spot_price Numeric. Current stock price
#' @param observation_date Date. The observation date
#' @param moneyness_threshold Numeric. Maximum abs(strike/spot - 1) to consider ATM
#'
#' @return Tibble with one row per expiration containing ATM IV and days to expiration
#' @export
calculate_iv_term_structure <- function(options_chain,
                                        spot_price,
                                        observation_date,
                                        moneyness_threshold = 0.05) {
  if (nrow(options_chain) == 0 || is.na(spot_price) || spot_price <= 0) {
    return(tibble::tibble(
      ticker = character(),
      observation_date = as.Date(character()),
      expiration = as.Date(character()),
      days_to_expiration = numeric(),
      atm_iv = numeric(),
      atm_iv_call = numeric(),
      atm_iv_put = numeric(),
      atm_strike = numeric(),
      spot_price = numeric()
    ))
  }

  observation_date <- as.Date(observation_date)

  # Extract ATM options per (expiration, type)
  atm <- extract_atm_options(options_chain, spot_price, moneyness_threshold)

  if (nrow(atm) == 0) {
    return(tibble::tibble(
      ticker = character(),
      observation_date = as.Date(character()),
      expiration = as.Date(character()),
      days_to_expiration = numeric(),
      atm_iv = numeric(),
      atm_iv_call = numeric(),
      atm_iv_put = numeric(),
      atm_strike = numeric(),
      spot_price = numeric()
    ))
  }

  # Filter out zero/NA IVs
  atm <- atm %>%
    dplyr::filter(!is.na(implied_volatility), implied_volatility > 0)

  if (nrow(atm) == 0) {
    return(tibble::tibble(
      ticker = character(),
      observation_date = as.Date(character()),
      expiration = as.Date(character()),
      days_to_expiration = numeric(),
      atm_iv = numeric(),
      atm_iv_call = numeric(),
      atm_iv_put = numeric(),
      atm_strike = numeric(),
      spot_price = numeric()
    ))
  }

  # Pivot to get call/put IV side by side per expiration
  call_iv <- atm %>%
    dplyr::filter(type == "call") %>%
    dplyr::select(expiration, atm_iv_call = implied_volatility, strike_call = strike)

  put_iv <- atm %>%
    dplyr::filter(type == "put") %>%
    dplyr::select(expiration, atm_iv_put = implied_volatility, strike_put = strike)

  # Full join on expiration to handle cases where only call or put exists
  term_structure <- dplyr::full_join(call_iv, put_iv, by = "expiration") %>%
    dplyr::mutate(
      # Average call/put IV; use whichever is available if only one exists
      atm_iv = dplyr::case_when(
        !is.na(atm_iv_call) & !is.na(atm_iv_put) ~ (atm_iv_call + atm_iv_put) / 2,
        !is.na(atm_iv_call) ~ atm_iv_call,
        TRUE ~ atm_iv_put
      ),
      atm_strike = dplyr::coalesce(strike_call, strike_put),
      days_to_expiration = as.numeric(expiration - observation_date),
      observation_date = observation_date,
      spot_price = spot_price,
      ticker = options_chain$ticker[1]
    ) %>%
    # Filter out expired options
    dplyr::filter(days_to_expiration > 0) %>%
    dplyr::select(
      ticker, observation_date, expiration, days_to_expiration,
      atm_iv, atm_iv_call, atm_iv_put, atm_strike, spot_price
    ) %>%
    dplyr::arrange(days_to_expiration)

  term_structure
}
