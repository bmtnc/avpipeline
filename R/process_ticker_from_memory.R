#' Process TTM Pipeline for Single Ticker from Pre-loaded Data
#'
#' Processes a ticker through TTM pipeline using pre-loaded dataframes.
#'
#' @param ticker character: Stock ticker symbol
#' @param all_data list: Named list with all data types pre-loaded
#' @param start_date Date: Start date for filtering financial data
#' @param threshold numeric: Z-score threshold for anomaly detection (default: 4)
#' @param lookback integer: Lookback for anomaly detection (default: 5)
#' @param lookahead integer: Lookahead for anomaly detection (default: 5)
#' @param end_window_size integer: Window size for end-of-series detection (default: 5)
#' @param end_threshold numeric: Threshold for end-of-series detection (default: 3)
#' @param min_obs integer: Minimum observations for anomaly detection (default: 10)
#' @return tibble or NULL: TTM per-share financial data
#' @keywords internal
process_ticker_from_memory <- function(
  ticker,
  all_data,
  start_date,
  threshold = 4,
  lookback = 5,
  lookahead = 5,
  end_window_size = 5,
  end_threshold = 3,
  min_obs = 10
) {
  validate_character_scalar(ticker, name = "ticker")

  # Filter data for this ticker
  balance_sheet <- all_data$balance_sheet |>
    dplyr::filter(ticker == !!ticker)
  income_statement <- all_data$income_statement |>
    dplyr::filter(ticker == !!ticker)
  cash_flow <- all_data$cash_flow |>
    dplyr::filter(ticker == !!ticker)
  earnings <- all_data$earnings |>
    dplyr::filter(ticker == !!ticker)
  price_data <- all_data$price |>
    dplyr::filter(ticker == !!ticker)
  splits_data <- all_data$splits |>
    dplyr::filter(ticker == !!ticker)
  overview_data <- all_data$overview |>
    dplyr::filter(ticker == !!ticker)

  if (nrow(earnings) == 0) {
    return(NULL)
  }
  if (nrow(price_data) == 0) {
    return(NULL)
  }

  financial_statements <- validate_and_prepare_statements(
    cash_flow = cash_flow,
    income_statement = income_statement,
    balance_sheet = balance_sheet,
    earnings = earnings,
    threshold = threshold,
    lookback = lookback,
    lookahead = lookahead,
    end_window_size = end_window_size,
    end_threshold = end_threshold,
    min_obs = min_obs
  )

  if (nrow(financial_statements) == 0) {
    return(NULL)
  }

  market_cap <- build_market_cap_with_splits(
    price_data = price_data,
    splits_data = splits_data,
    financial_statements = financial_statements,
    start_date = start_date
  )

  result <- calculate_unified_ttm_per_share_metrics(
    financial_statements = financial_statements,
    price_data = price_data,
    market_cap = market_cap
  )

  if (nrow(overview_data) > 0) {
    result <- dplyr::mutate(
      result,
      cik = overview_data$cik[1],
      exchange = overview_data$exchange[1],
      currency = overview_data$currency[1],
      country = overview_data$country[1],
      sector = overview_data$sector[1],
      industry = overview_data$industry[1]
    )
  } else {
    result <- dplyr::mutate(
      result,
      cik = NA_character_,
      exchange = NA_character_,
      currency = NA_character_,
      country = NA_character_,
      sector = NA_character_,
      industry = NA_character_
    )
  }

  result
}
