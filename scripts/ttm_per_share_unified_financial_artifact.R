# TTM Per-Share Unified Financial Artifact Creator

# Load package functions
devtools::load_all()

message("Creating TTM per-share artifact (essential columns only)...")

# Load artifacts
artifacts <- load_financial_artifacts()
financial_statements <- artifacts$financial_statements
market_cap_data <- artifacts$market_cap_data
price_data <- artifacts$price_data

# Calculate TTM metrics
flow_metrics <- c(get_income_statement_metrics(), get_cash_flow_metrics())
balance_sheet_metrics <- get_balance_sheet_metrics()
ttm_metrics <- calculate_ttm_metrics(financial_statements, flow_metrics) %>%
  dplyr::mutate(date = reportedDate)

# Join daily and financial data
unified_data <- join_daily_and_financial_data(price_data, market_cap_data, ttm_metrics)

# Forward fill financial data by ticker
unified_data <- forward_fill_financial_data(unified_data)

# Calculate per-share metrics
ttm_flow_metrics <- paste0(flow_metrics, "_ttm")
all_financial_metrics <- c(balance_sheet_metrics, flow_metrics, ttm_flow_metrics)
unified_per_share_data <- calculate_per_share_metrics(unified_data, all_financial_metrics)

# Select essential columns only
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
  "initial_date",
  "latest_date",
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

# Write output
arrow::write_parquet(ttm_per_share_data, "cache/ttm_per_share_financial_artifact.parquet")

message("✓ Essential TTM per-share artifact created!")
message("Final dataset: ", nrow(ttm_per_share_data), " observations x ", ncol(ttm_per_share_data), " columns")
