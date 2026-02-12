#' Build Options Term Structure for One Ticker
#'
#' Processes raw options chain data across all observation dates, producing
#' raw and interpolated IV term structures.
#'
#' @param ticker character: Stock ticker symbol
#' @param options_data Tibble of raw option chain data (all dates for one ticker)
#' @param price_data Tibble of daily price data with date and adjusted_close columns
#' @param tenors Numeric vector of standard tenor days for interpolation
#' @param moneyness_threshold Numeric. Maximum abs(strike/spot - 1) to consider ATM
#'
#' @return List with raw_term_structure and interpolated_term_structure tibbles
#' @export
build_options_term_structure <- function(ticker,
                                         options_data,
                                         price_data,
                                         tenors = c(30, 60, 90, 180, 365),
                                         moneyness_threshold = 0.05) {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")

  empty_result <- list(
    raw_term_structure = tibble::tibble(
      ticker = character(), observation_date = as.Date(character()),
      expiration = as.Date(character()), days_to_expiration = numeric(),
      atm_iv = numeric(), atm_iv_call = numeric(), atm_iv_put = numeric(),
      atm_strike = numeric(), spot_price = numeric()
    ),
    interpolated_term_structure = tibble::tibble(
      ticker = character(), observation_date = as.Date(character()),
      tenor_days = numeric(), iv = numeric()
    )
  )

  if (is.null(options_data) || nrow(options_data) == 0) {
    return(empty_result)
  }

  observation_dates <- sort(unique(options_data$date))
  raw_results <- list()
  interp_results <- list()

  for (obs_date in observation_dates) {
    obs_date <- as.Date(obs_date, origin = "1970-01-01")

    # Get spot price from price data on this date
    spot <- price_data %>%
      dplyr::filter(date == obs_date) %>%
      dplyr::pull(adjusted_close)

    if (length(spot) == 0 || is.na(spot[1])) {
      # Try closest prior date within 5 days
      spot <- price_data %>%
        dplyr::filter(date >= obs_date - 5, date <= obs_date) %>%
        dplyr::arrange(dplyr::desc(date)) %>%
        dplyr::slice_head(n = 1) %>%
        dplyr::pull(adjusted_close)
    }

    if (length(spot) == 0 || is.na(spot[1])) next
    spot_price <- spot[1]

    chain <- options_data %>%
      dplyr::filter(date == obs_date)

    raw_ts <- calculate_iv_term_structure(
      chain, spot_price, obs_date, moneyness_threshold
    )

    if (nrow(raw_ts) > 0) {
      raw_results[[length(raw_results) + 1]] <- raw_ts
      interp_results[[length(interp_results) + 1]] <-
        interpolate_iv_to_standard_tenors(raw_ts, tenors)
    }
  }

  if (length(raw_results) == 0) {
    return(empty_result)
  }

  list(
    raw_term_structure = dplyr::bind_rows(raw_results),
    interpolated_term_structure = dplyr::bind_rows(interp_results)
  )
}
