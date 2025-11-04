#' Calculate Unified TTM Per-Share Financial Metrics
#'
#' Orchestrates calculation of trailing twelve month (TTM) metrics and per-share
#' values by combining financial statements, market cap, and daily price data.
#' Produces a unified daily-frequency dataset with forward-filled financial metrics.
#'
#' @param financial_statements tibble: Cleaned and validated financial statements
#' @param price_data tibble: Daily price data with OHLCV columns
#' @param market_cap tibble: Daily market cap with split adjustments
#' @return tibble: Daily-frequency dataset with TTM per-share metrics, prices, and quality flags
#' @keywords internal
calculate_unified_ttm_per_share_metrics <- function(
  financial_statements,
  price_data,
  market_cap
) {
  # Get metric lists
  flow_metrics <- c(get_income_statement_metrics(), get_cash_flow_metrics())
  balance_sheet_metrics <- get_balance_sheet_metrics()
  
  # Calculate TTM metrics
  ttm_metrics <- calculate_ttm_metrics(financial_statements, flow_metrics) %>%
  dplyr::mutate(date = reportedDate)
  
  # Join daily and financial data
  unified_data <- join_daily_and_financial_data(price_data, market_cap, ttm_metrics)
  
  # Forward fill financial data
  unified_data <- forward_fill_financial_data(unified_data)
  
  # Calculate per-share metrics
  ttm_flow_metrics <- paste0(flow_metrics, "_ttm")
  all_financial_metrics <- c(balance_sheet_metrics, ttm_flow_metrics)
  unified_per_share_data <- calculate_per_share_metrics(unified_data, all_financial_metrics)
  
  # Select essential columns
  ttm_per_share_data <- select_essential_columns(unified_per_share_data)
  
  # Add derived financial metrics
  ttm_per_share_data <- add_derived_financial_metrics(ttm_per_share_data)
  
  # Add data quality flag
  ttm_per_share_data <- ttm_per_share_data %>%
  dplyr::mutate(
    has_complete_financial_data =
    !is.na(totalRevenue_ttm_per_share) &
    !is.na(totalAssets_per_share) &
    !is.na(operatingCashflow_ttm_per_share)
  )
  
  # Reorder columns: ticker, dates, meta, flag, then everything else
  date_cols <- c(
    "date",
    "fiscalDateEnding",
    "reportedDate",
    "calendar_quarter_ending"
  )
  
  meta_cols <- c(
    "ticker",
    "open",
    "high",
    "low",
    "adjusted_close",
    "volume",
    "dividend_amount",
    "split_coefficient",
    "n",
    "post_filing_split_multiplier",
    "effective_shares_outstanding",
    "commonStockSharesOutstanding",
    "market_cap"
  )
  
  ttm_per_share_data <- ttm_per_share_data %>%
  dplyr::select(
    ticker,
    dplyr::any_of(date_cols),
    dplyr::any_of(meta_cols),
    has_complete_financial_data,
    dplyr::everything()
  ) %>%
  dplyr::arrange(ticker, date)
  
  ttm_per_share_data
}
