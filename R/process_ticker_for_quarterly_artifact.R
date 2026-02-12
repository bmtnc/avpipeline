#' Process Ticker for Quarterly TTM Artifact
#'
#' Processes a single ticker to produce quarterly TTM financial data.
#' Does NOT forward-fill to daily or compute per-share metrics - that happens
#' on-demand when joining with price data.
#'
#' @param ticker character: Stock ticker symbol
#' @param all_data list: Named list with all data types, each pre-split by ticker
#' @param start_date Date: Start date for filtering financial data
#' @param threshold numeric: Z-score threshold for anomaly detection (default: 4)
#' @param lookback integer: Lookback for anomaly detection (default: 5)
#' @param lookahead integer: Lookahead for anomaly detection (default: 5)
#' @param end_window_size integer: Window size for end-of-series detection (default: 5)
#' @param end_threshold numeric: Threshold for end-of-series detection (default: 3)
#' @param min_obs integer: Minimum observations for anomaly detection (default: 10)
#' @return tibble or NULL: Quarterly TTM financial data
#' @keywords internal
process_ticker_for_quarterly_artifact <- function(
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

  # Look up pre-split ticker data (O(1) list index vs O(N) filter scan)
  balance_sheet <- all_data$balance_sheet[[ticker]] %||% tibble::tibble()
  income_statement <- all_data$income_statement[[ticker]] %||% tibble::tibble()
  cash_flow <- all_data$cash_flow[[ticker]] %||% tibble::tibble()
  earnings <- all_data$earnings[[ticker]] %||% tibble::tibble()
  overview_data <- all_data$overview[[ticker]] %||% tibble::tibble()

  if (nrow(earnings) == 0) {
    return(NULL)
  }

  # Validate and prepare financial statements
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

  # Calculate TTM metrics for flow-based metrics
  flow_metrics <- c(get_income_statement_metrics(), get_cash_flow_metrics())
  result <- calculate_ttm_metrics(financial_statements, flow_metrics)

  # LEFT JOIN quarterly earnings estimates
  earnings_estimates <- all_data$earnings_estimates[[ticker]] %||% tibble::tibble()
  if (nrow(earnings_estimates) > 0) {
    quarterly_estimates <- earnings_estimates %>%
      dplyr::filter(grepl("quarter", horizon, ignore.case = TRUE)) %>%
      dplyr::select(ticker, fiscalDateEnding, dplyr::all_of(get_earnings_estimates_metrics()))
    result <- dplyr::left_join(result, quarterly_estimates, by = c("ticker", "fiscalDateEnding"))
  } else {
    for (col in get_earnings_estimates_metrics()) {
      result[[col]] <- NA_real_
    }
  }

  # Add overview metadata
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
