# ============================================================================
# Complete TTM Per-Share Financial Artifact Pipeline
# ============================================================================
# Consolidates three pipeline stages into one unified, in-memory workflow:
#   1. Financial Statements Artifact (quarterly data)
#   2. Market Cap Artifact (daily market data with split adjustments)
#   3. TTM Per-Share Artifact (final output)
#
# Output: cache/ttm_per_share_financial_artifact.parquet
# ============================================================================

devtools::load_all()

# ============================================================================
# STAGE 0: Fetch Financial Data from API
# ============================================================================
message("Stage 0: Fetching financial data from Alpha Vantage API...")

tickers <- get_financial_statement_tickers(etf_symbol = "QQQ")

# Fetch financial statements
cache_paths <- get_financial_cache_paths()
fetch_all_financial_statements(tickers, cache_paths)
message("  ✓ Financial statements fetched")

# Fetch price data
price_cache <- "cache/price_artifact.parquet"
fetch_multiple_tickers_with_cache(
  tickers = tickers,
  cache_file = price_cache,
  single_fetch_func = function(ticker, ...) {
    fetch_single_ticker_data(ticker, PRICE_CONFIG, ...)
  },
  cache_reader_func = read_cached_data_parquet,
  data_type_name = PRICE_CONFIG$data_type_name,
  delay_seconds = PRICE_CONFIG$default_delay,
  outputsize = "full",
  datatype = "json"
)
price_data <- arrow::read_parquet(price_cache)
message("  ✓ Price data fetched")

# Fetch splits data (use financial + price ticker intersection)
financial_tickers <- unique(load_all_artifact_statements()$earnings$ticker)
price_tickers <- unique(price_data$ticker)
splits_tickers <- intersect(financial_tickers, price_tickers)

splits_cache <- "cache/splits_artifact.parquet"
fetch_multiple_tickers_with_cache(
  tickers = splits_tickers,
  cache_file = splits_cache,
  single_fetch_func = function(ticker, ...) {
    fetch_single_ticker_data(ticker, SPLITS_CONFIG, ...)
  },
  cache_reader_func = read_cached_data_parquet,
  data_type_name = SPLITS_CONFIG$data_type_name,
  delay_seconds = SPLITS_CONFIG$default_delay
)
splits_data <- arrow::read_parquet(splits_cache)
message("  ✓ Splits data fetched")
message("  ✓ All data fetched and cached")

# ============================================================================
# STAGE 1: Financial Statements Artifact (In-Memory)
# ============================================================================
message("Stage 1: Building financial statements artifact...")

all_statements <- load_all_artifact_statements()

statements_cleaned <- remove_all_na_financial_observations(list(
  cash_flow = all_statements$cash_flow,
  income_statement = all_statements$income_statement,
  balance_sheet = all_statements$balance_sheet
))

statements_cleaned <- clean_all_statement_anomalies(
  statements = statements_cleaned,
  threshold = 4,
  lookback = 5,
  lookahead = 5,
  end_window_size = 5,
  end_threshold = 3,
  min_obs = 10
)

all_statements_aligned <- align_statement_tickers(list(
  earnings = all_statements$earnings,
  cash_flow = statements_cleaned$cash_flow,
  income_statement = statements_cleaned$income_statement,
  balance_sheet = statements_cleaned$balance_sheet
))

valid_dates <- align_statement_dates(list(
  cash_flow = all_statements_aligned$cash_flow,
  income_statement = all_statements_aligned$income_statement,
  balance_sheet = all_statements_aligned$balance_sheet
))

financial_statements <- join_all_financial_statements(all_statements_aligned, valid_dates)

financial_statements <- add_quality_flags(financial_statements)

financial_statements <- filter_essential_financial_columns(financial_statements)

financial_statements <- validate_quarterly_continuity(financial_statements)

financial_statements <- standardize_to_calendar_quarters(financial_statements)

message("  ✓ Financial statements artifact complete: ", nrow(financial_statements), " rows")

# ============================================================================
# STAGE 2: Market Cap Artifact (In-Memory)
# ============================================================================
message("Stage 2: Building market cap artifact...")

# Load price and splits data
prices <- arrow::read_parquet("cache/price_artifact.parquet")
splits_data <- arrow::read_parquet("cache/splits_artifact.parquet")

# Define ticker universe
financial_tickers <- unique(financial_statements$ticker)
price_tickers <- unique(prices$ticker)
target_tickers <- intersect(financial_tickers, price_tickers)

message("  Target tickers: ", length(target_tickers))

# Clean splits data
splits_clean <- splits_data %>%
  dplyr::filter(ticker %in% target_tickers) %>%
  dplyr::mutate(split_factor = as.numeric(split_factor)) %>%
  dplyr::filter(!is.na(split_factor) & split_factor > 0) %>%
  dplyr::select(ticker, date = effective_date, split_factor) %>%
  dplyr::arrange(ticker, date)

# Clean price data
prices_clean <- prices %>%
  dplyr::filter(
    ticker %in% target_tickers,
    date >= as.Date("2004-12-31"),
    !is.na(close) & close > 0
  ) %>%
  dplyr::mutate(close = as.numeric(close)) %>%
  dplyr::select(ticker, date, close) %>%
  dplyr::distinct() %>%
  dplyr::arrange(ticker, date)

# Clean financial data
financial_clean <- financial_statements %>%
  dplyr::filter(
    ticker %in% target_tickers,
    fiscalDateEnding >= as.Date("2004-12-31")
  ) %>%
  dplyr::mutate(
    commonStockSharesOutstanding = as.numeric(commonStockSharesOutstanding)
  ) %>%
  dplyr::filter(
    !is.na(commonStockSharesOutstanding) &
    commonStockSharesOutstanding > 0
  ) %>%
  dplyr::select(ticker, reportedDate, commonStockSharesOutstanding) %>%
  dplyr::arrange(ticker, reportedDate)

# Build daily shares outstanding
daily_shares <- prices_clean %>%
  dplyr::left_join(
    financial_clean,
    by = dplyr::join_by(ticker, date >= reportedDate)
  ) %>%
  dplyr::group_by(ticker, date) %>%
  dplyr::slice_max(reportedDate, n = 1, with_ties = FALSE) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(
    has_financial_data = !is.na(commonStockSharesOutstanding),
    commonStockSharesOutstanding = as.numeric(commonStockSharesOutstanding)
  ) %>%
  dplyr::arrange(ticker, date)

# Compute cumulative split factors
prices_with_splits <- prices_clean %>%
  dplyr::left_join(splits_clean, by = c("ticker", "date")) %>%
  dplyr::group_by(ticker) %>%
  dplyr::arrange(date) %>%
  dplyr::mutate(
    split_factor = dplyr::coalesce(split_factor, 1),
    cum_split_factor = cumprod(split_factor)
  ) %>%
  dplyr::ungroup()

# Assemble market cap table with corrected split adjustment
market_cap <- daily_shares %>%
  dplyr::left_join(
    prices_with_splits %>%
      dplyr::select(ticker, date, cum_split_factor),
    by = c("ticker", "date")
  ) %>%
  dplyr::group_by(ticker) %>%
  dplyr::arrange(date) %>%
  dplyr::mutate(
    post_filing_split_multiplier = dplyr::case_when(
      is.na(reportedDate) | is.na(cum_split_factor) ~ NA_real_,
      TRUE ~ {
        filing_date_indices <- which(date <= reportedDate)
        if (length(filing_date_indices) == 0) {
          filing_date_factor <- 1
        } else {
          last_filing_index <- max(filing_date_indices)
          filing_date_factor <- cum_split_factor[last_filing_index]
          if (is.na(filing_date_factor)) filing_date_factor <- 1
        }
        cum_split_factor / filing_date_factor
      }
    ),
    effective_shares_outstanding =
      commonStockSharesOutstanding *
      dplyr::coalesce(post_filing_split_multiplier, 1),
    market_cap = dplyr::if_else(
      has_financial_data,
      close * effective_shares_outstanding / 1e6,
      NA_real_
    )
  ) %>%
  dplyr::ungroup() %>%
  dplyr::select(
    ticker, date, 
    post_filing_split_multiplier, effective_shares_outstanding,
    market_cap
  ) %>%
  dplyr::arrange(ticker, date)

message("  ✓ Market cap artifact complete: ", nrow(market_cap), " rows")

# ============================================================================
# STAGE 3: Price Data
# ============================================================================
message("Stage 3: Loading price data...")

price <- arrow::read_parquet("cache/price_artifact.parquet")

message("  ✓ Price data loaded: ", nrow(price), " rows")

# ============================================================================
# STAGE 4: TTM Per-Share Artifact
# ============================================================================
message("Stage 4: Building TTM per-share artifact...")

# Calculate TTM metrics
flow_metrics <- c(get_income_statement_metrics(), get_cash_flow_metrics())
balance_sheet_metrics <- get_balance_sheet_metrics()

ttm_metrics <- calculate_ttm_metrics(financial_statements, flow_metrics) %>%
  dplyr::mutate(date = reportedDate)

# Join daily and financial data
unified_data <- join_daily_and_financial_data(price, market_cap, ttm_metrics)

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

message("  ✓ TTM per-share artifact complete: ", nrow(ttm_per_share_data), " rows")

# ============================================================================
# STAGE 5: Save Output
# ============================================================================
message("Stage 5: Saving artifact...")

arrow::write_parquet(ttm_per_share_data, "cache/ttm_per_share_financial_artifact.parquet")

message("✓ Pipeline complete!")
message("Final dataset: ", nrow(ttm_per_share_data), " observations × ", ncol(ttm_per_share_data), " columns")
