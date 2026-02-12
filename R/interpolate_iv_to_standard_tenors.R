#' Interpolate IV Term Structure to Standard Tenors
#'
#' @param term_structure Tibble from calculate_iv_term_structure() with
#'   days_to_expiration and atm_iv columns
#' @param tenors Numeric vector of target tenor days (default: 30, 60, 90, 180, 365)
#'
#' @return Tibble with one row per tenor containing interpolated IV
#' @export
interpolate_iv_to_standard_tenors <- function(term_structure,
                                               tenors = c(30, 60, 90, 180, 365)) {
  if (nrow(term_structure) == 0) {
    return(tibble::tibble(
      ticker = character(),
      observation_date = as.Date(character()),
      tenor_days = numeric(),
      iv = numeric()
    ))
  }

  ticker_val <- term_structure$ticker[1]
  obs_date <- term_structure$observation_date[1]

  # Need at least 2 points for interpolation
  valid <- term_structure %>%
    dplyr::filter(!is.na(atm_iv), !is.na(days_to_expiration))

  if (nrow(valid) < 2) {
    # With only 1 point, can only match exact tenor
    interpolated_iv <- ifelse(
      tenors %in% valid$days_to_expiration,
      valid$atm_iv[match(tenors, valid$days_to_expiration)],
      NA_real_
    )
  } else {
    # Linear interpolation, no extrapolation (rule = 1 returns NA outside range)
    interpolated_iv <- approx(
      x = valid$days_to_expiration,
      y = valid$atm_iv,
      xout = tenors,
      rule = 1
    )$y
  }

  tibble::tibble(
    ticker = ticker_val,
    observation_date = obs_date,
    tenor_days = tenors,
    iv = interpolated_iv
  )
}
