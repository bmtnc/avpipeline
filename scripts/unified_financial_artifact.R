# =============================================================================
# Unified Financial Artifact Constructor
# =============================================================================
#
# COMPREHENSIVE THREE-WAY INTEGRATION:
# ------------------------------------
# This script creates a sophisticated unified dataset by integrating:
# 1. market_cap_artifact_vectorized.csv - Daily market data with split-adjusted shares
# 2. price_artifact.csv - Daily price data with volume and dividends
# 3. financial_statements_artifact.csv - Quarterly financial data
#
# CORE INNOVATION:
# ----------------
# - Uses effective_shares_outstanding as universal denominator for per-share metrics
# - Leverages proven forward-filling methodology from market_cap_artifact.R
# - Creates comprehensive valuation ratios and enterprise value calculations
# - Maintains split-adjustment precision across all financial metrics
#
# RESULT:
# -------
# Daily frequency dataset with ~180+ columns combining:
# - Market capitalization with split-adjusted shares
# - Complete price and volume data
# - Forward-filled quarterly financial statements
# - Comprehensive per-share metrics
# - Valuation ratios (P/E, P/B, P/S, EV/EBITDA, etc.)
# - Enterprise value calculations
# - Data quality indicators
# =============================================================================

# ---- SECTION 0 : helper sources ---------------------------------------------
source("R/read_cached_data.R")          # custom I/O helpers
source("R/alpha_vantage_configs.R")     # centralised config lists

# ---- SECTION 1 : load cached artifacts --------------------------------------
cat("Loading cached artifacts …\n")

# Load market cap artifact (daily market data with split-adjusted shares)
market_cap_data <- read_cached_data(
  "cache/market_cap_artifact_vectorized.csv",
  date_columns = c("date", "reportedDate", "as_of_date")
)

# Load price artifact (daily price data)
price_data <- read_cached_data(
  "cache/price_artifact.csv",
  date_columns = PRICE_CONFIG$cache_date_columns
)

# Load financial statements artifact (quarterly financial data)
financial_statements <- read_cached_data(
  "cache/financial_statements_artifact.csv",
  date_columns = c("fiscalDateEnding", "reportedDate", "as_of_date", "calendar_quarter_ending")
)

# ---- SECTION 1.1 : validate data availability -------------------------------
cat("Validating data availability …\n")

if (nrow(market_cap_data) == 0) {
  stop("Market cap artifact is empty. Run scripts/market_cap_artifact.R first.")
}

if (nrow(price_data) == 0) {
  stop("Price artifact is empty. Run scripts/price_artifact.R first.")
}

if (nrow(financial_statements) == 0) {
  stop("Financial statements artifact is empty. Run scripts/financial_statements_artifact.R first.")
}

# ---- SECTION 1.2 : determine common ticker universe -------------------------
market_cap_tickers <- unique(market_cap_data$ticker)
price_tickers <- unique(price_data$ticker)
financial_tickers <- unique(financial_statements$ticker)

# Find intersection of all three datasets
common_tickers <- Reduce(intersect, list(market_cap_tickers, price_tickers, financial_tickers))

cat(
  "Ticker universe:\n",
  " • Market cap: ", length(market_cap_tickers), "\n",
  " • Price data: ", length(price_tickers), "\n",
  " • Financial statements: ", length(financial_tickers), "\n",
  " • Common tickers: ", length(common_tickers), "\n"
)

if (length(common_tickers) == 0) {
  stop("No common tickers across all three datasets.")
}

# ---- SECTION 2 : data cleaning & preparation --------------------------------
cat("Cleaning and preparing data …\n")

# Clean market cap data
market_cap_clean <- market_cap_data %>%
  dplyr::filter(
    ticker %in% common_tickers,
    date >= as.Date("2004-12-31"),
    !is.na(close) & close > 0
  ) %>%
  dplyr::select(
    ticker, date, close_market_cap = close,
    commonStockSharesOutstanding, reportedDate,
    post_filing_split_multiplier, effective_shares_outstanding,
    market_cap, has_financial_data, days_since_financial_report, as_of_date
  ) %>%
  dplyr::arrange(ticker, date)

# Clean price data
price_clean <- price_data %>%
  dplyr::filter(
    ticker %in% common_tickers,
    date >= as.Date("2004-12-31"),
    !is.na(close) & close > 0
  ) %>%
  dplyr::select(
    ticker, date, open, high, low, close, adjusted_close, volume,
    dividend_amount, split_coefficient
  ) %>%
  dplyr::arrange(ticker, date)

# Clean financial statements
financial_clean <- financial_statements %>%
  dplyr::filter(
    ticker %in% common_tickers,
    fiscalDateEnding >= as.Date("2004-12-31")
  ) %>%
  dplyr::arrange(ticker, reportedDate)

cat(
  "Clean data rows:\n",
  " • Market cap: ", nrow(market_cap_clean), "\n",
  " • Price data: ", nrow(price_clean), "\n",
  " • Financial statements: ", nrow(financial_clean), "\n"
)

# ---- SECTION 3 : efficient three-way join with forward-filling --------------
cat("Implementing efficient three-way join with forward-filling …\n")

# Step 1: Join market cap with price data (both daily, straightforward join)
market_price_joined <- market_cap_clean %>%
  dplyr::left_join(
    price_clean,
    by = c("ticker", "date")
  ) %>%
  dplyr::mutate(
    close_final = dplyr::coalesce(close, close_market_cap),
    has_price_data = !is.na(close)
  ) %>%
  dplyr::select(-close, -close_market_cap) %>%
  dplyr::rename(close = close_final)

# Step 2: Simple join on exact dates + forward fill
unified_base <- market_price_joined %>%
  # Left join on exact date match (will be sparse - only on reporting dates)
  dplyr::left_join(
    financial_clean,
    by = c("ticker", "date" = "reportedDate"),
    suffix = c("", "_fs")
  ) %>%
  # Create a column to track when financial data was reported
  dplyr::mutate(
    financial_reportedDate = dplyr::if_else(
      !is.na(fiscalDateEnding),  # If we have financial data on this date
      date,  # Then this date IS the reportedDate
      as.Date(NA)
    )
  ) %>%
  # Forward fill financial data AND the reportedDate within each ticker
  dplyr::group_by(ticker) %>%
  dplyr::arrange(date) %>%
  tidyr::fill(
    # Fill all financial statement columns forward
    dplyr::all_of(names(financial_clean)[!names(financial_clean) %in% c("ticker", "reportedDate", "as_of_date")]),
    financial_reportedDate,  # Also forward-fill when this data was reported
    .direction = "down"
  ) %>%
  dplyr::ungroup() %>%
  # Create data quality indicators
  dplyr::mutate(
    has_financial_statements = !is.na(fiscalDateEnding),
    days_since_financial_report = dplyr::if_else(
      !is.na(financial_reportedDate),
      as.numeric(date - financial_reportedDate),
      NA_real_
    )
  )

cat("Unified base dataset: ", nrow(unified_base), " rows\n")

# ---- SECTION 4 : per-share metrics calculation ------------------------------
cat("Calculating per-share metrics …\n")

unified_with_metrics <- unified_base %>%
  dplyr::mutate(
    # Validate effective shares outstanding
    valid_shares = !is.na(effective_shares_outstanding) & effective_shares_outstanding > 0,

    # Revenue metrics per share
    revenue_per_share = dplyr::if_else(
      valid_shares & !is.na(totalRevenue),
      totalRevenue / commonStockSharesOutstanding,
      NA_real_
    ),

    # Asset metrics per share
    assets_per_share = dplyr::if_else(
      valid_shares & !is.na(totalAssets),
      totalAssets / commonStockSharesOutstanding,
      NA_real_
    ),

    book_value_per_share = dplyr::if_else(
      valid_shares & !is.na(totalShareholderEquity),
      totalShareholderEquity / commonStockSharesOutstanding,
      NA_real_
    ),

    tangible_book_value_per_share = dplyr::if_else(
      valid_shares & !is.na(totalShareholderEquity) & !is.na(intangibleAssets),
      (totalShareholderEquity - dplyr::coalesce(intangibleAssets, 0)) / commonStockSharesOutstanding,
      NA_real_
    ),

    # Cash flow metrics per share
    operating_cash_flow_per_share = dplyr::if_else(
      valid_shares & !is.na(operatingCashflow),
      operatingCashflow / commonStockSharesOutstanding,
      NA_real_
    ),

    free_cash_flow_per_share = dplyr::if_else(
      valid_shares & !is.na(operatingCashflow) & !is.na(capitalExpenditures),
      (operatingCashflow - dplyr::coalesce(capitalExpenditures, 0)) / commonStockSharesOutstanding,
      NA_real_
    ),

    capex_per_share = dplyr::if_else(
      valid_shares & !is.na(capitalExpenditures),
      capitalExpenditures / commonStockSharesOutstanding,
      NA_real_
    ),

    # Profitability metrics per share
    earnings_per_share = dplyr::if_else(
      valid_shares & !is.na(netIncome),
      netIncome / commonStockSharesOutstanding,
      NA_real_
    ),

    ebit_per_share = dplyr::if_else(
      valid_shares & !is.na(ebit),
      ebit / commonStockSharesOutstanding,
      NA_real_
    ),

    ebitda_per_share = dplyr::if_else(
      valid_shares & !is.na(ebitda),
      ebitda / commonStockSharesOutstanding,
      NA_real_
    ),

    # Debt metrics per share
    debt_per_share = dplyr::if_else(
      valid_shares & !is.na(longTermDebt),
      longTermDebt / commonStockSharesOutstanding,
      NA_real_
    ),

    net_debt_per_share = dplyr::if_else(
      valid_shares & !is.na(longTermDebt) & !is.na(cashAndCashEquivalentsAtCarryingValue),
      (longTermDebt - dplyr::coalesce(cashAndCashEquivalentsAtCarryingValue, 0)) / commonStockSharesOutstanding,
      NA_real_
    )
  )

# ---- SECTION 5 : valuation ratios calculation -------------------------------
cat("Calculating valuation ratios …\n")

unified_with_ratios <- unified_with_metrics %>%
  dplyr::mutate(
    # Price-to-X ratios
    price_to_earnings = dplyr::if_else(
      !is.na(close) & !is.na(earnings_per_share) & earnings_per_share > 0,
      close / earnings_per_share,
      NA_real_
    ),

    price_to_book = dplyr::if_else(
      !is.na(close) & !is.na(book_value_per_share) & book_value_per_share > 0,
      close / book_value_per_share,
      NA_real_
    ),

    price_to_sales = dplyr::if_else(
      !is.na(close) & !is.na(revenue_per_share) & revenue_per_share > 0,
      close / revenue_per_share,
      NA_real_
    ),

    price_to_cash_flow = dplyr::if_else(
      !is.na(close) & !is.na(operating_cash_flow_per_share) & operating_cash_flow_per_share > 0,
      close / operating_cash_flow_per_share,
      NA_real_
    ),

    price_to_free_cash_flow = dplyr::if_else(
      !is.na(close) & !is.na(free_cash_flow_per_share) & free_cash_flow_per_share > 0,
      close / free_cash_flow_per_share,
      NA_real_
    ),

    # Enterprise value calculations
    enterprise_value = dplyr::if_else(
      !is.na(market_cap) & !is.na(longTermDebt) & !is.na(cashAndCashEquivalentsAtCarryingValue),
      market_cap + (longTermDebt / 1e6) - (cashAndCashEquivalentsAtCarryingValue / 1e6),
      NA_real_
    ),

    # Enterprise value ratios
    ev_to_revenue = dplyr::if_else(
      !is.na(enterprise_value) & !is.na(totalRevenue) & totalRevenue > 0,
      enterprise_value / (totalRevenue / 1e6),
      NA_real_
    ),

    ev_to_ebitda = dplyr::if_else(
      !is.na(enterprise_value) & !is.na(ebitda) & ebitda > 0,
      enterprise_value / (ebitda / 1e6),
      NA_real_
    ),

    # Market-cap-to-X ratios
    market_cap_to_revenue = dplyr::if_else(
      !is.na(market_cap) & !is.na(totalRevenue) & totalRevenue > 0,
      market_cap / (totalRevenue / 1e6),
      NA_real_
    ),

    market_cap_to_assets = dplyr::if_else(
      !is.na(market_cap) & !is.na(totalAssets) & totalAssets > 0,
      market_cap / (totalAssets / 1e6),
      NA_real_
    )
  )

# ---- SECTION 6 : data quality framework -------------------------------------
cat("Implementing data quality framework …\n")

unified_final <- unified_with_ratios %>%
  dplyr::mutate(
    # Data availability flags
    has_market_cap_data = !is.na(market_cap),
    has_complete_price_data = !is.na(close) & !is.na(volume),
    has_complete_financial_data = !is.na(totalRevenue) & !is.na(totalAssets) & !is.na(netIncome),
    has_complete_dataset = has_market_cap_data & has_complete_price_data & has_complete_financial_data,

    # Data quality indicators
    valid_per_share_metrics = valid_shares & has_complete_financial_data,

    # Data freshness
    days_since_financial_report = dplyr::if_else(
      !is.na(reportedDate) & date >= reportedDate,
      as.numeric(date - reportedDate),
      NA_real_
    ),

    data_freshness_quality = dplyr::case_when(
      is.na(days_since_financial_report) ~ "no_data",
      days_since_financial_report <= 90 ~ "fresh",
      days_since_financial_report <= 180 ~ "acceptable",
      days_since_financial_report > 180 ~ "stale",
      TRUE ~ "unknown"
    ),

    # Ratio validation flags
    extreme_pe_ratio = !is.na(price_to_earnings) & (price_to_earnings < 0 | price_to_earnings > 100),
    extreme_pb_ratio = !is.na(price_to_book) & (price_to_book < 0 | price_to_book > 50),
    extreme_ps_ratio = !is.na(price_to_sales) & (price_to_sales < 0 | price_to_sales > 100),

    # Update as_of_date for unified dataset
    as_of_date = Sys.Date()
  ) %>%
  # Remove temporary validation column
  dplyr::select(-valid_shares) %>%
  # Final sorting
  dplyr::arrange(ticker, date)

cat("Final unified dataset: ", nrow(unified_final), " rows, ", ncol(unified_final), " columns\n")

# ---- SECTION 7 : comprehensive validation -----------------------------------
cat("Running comprehensive validation …\n")

# Basic data quality checks
data_quality_summary <- unified_final %>%
  dplyr::summarise(
    total_observations = dplyr::n(),
    unique_tickers = dplyr::n_distinct(ticker),
    date_range_start = min(date),
    date_range_end = max(date),

    # Data availability
    has_market_cap = sum(has_market_cap_data),
    has_price_data = sum(has_complete_price_data),
    has_financial_data = sum(has_complete_financial_data),
    has_complete_data = sum(has_complete_dataset),

    # Per-share metrics
    valid_per_share = sum(valid_per_share_metrics),

    # Valuation ratios
    valid_pe_ratios = sum(!is.na(price_to_earnings)),
    valid_pb_ratios = sum(!is.na(price_to_book)),
    valid_ps_ratios = sum(!is.na(price_to_sales)),

    # Data freshness
    fresh_data = sum(data_freshness_quality == "fresh"),
    acceptable_data = sum(data_freshness_quality == "acceptable"),
    stale_data = sum(data_freshness_quality == "stale"),

    # Extreme ratios
    extreme_pe = sum(extreme_pe_ratio, na.rm = TRUE),
    extreme_pb = sum(extreme_pb_ratio, na.rm = TRUE),
    extreme_ps = sum(extreme_ps_ratio, na.rm = TRUE)
  )

cat("Data Quality Summary:\n")
cat(" • Total observations: ", data_quality_summary$total_observations, "\n")
cat(" • Unique tickers: ", data_quality_summary$unique_tickers, "\n")
cat(" • Date range: ", data_quality_summary$date_range_start, " to ", data_quality_summary$date_range_end, "\n")
cat(" • Complete datasets: ", data_quality_summary$has_complete_data,
    " (", round(100 * data_quality_summary$has_complete_data / data_quality_summary$total_observations, 1), "%)\n")
cat(" • Valid per-share metrics: ", data_quality_summary$valid_per_share, "\n")
cat(" • Valid P/E ratios: ", data_quality_summary$valid_pe_ratios, "\n")
cat(" • Fresh data: ", data_quality_summary$fresh_data,
    " | Acceptable: ", data_quality_summary$acceptable_data,
    " | Stale: ", data_quality_summary$stale_data, "\n")
cat(" • Extreme ratios - P/E: ", data_quality_summary$extreme_pe,
    " | P/B: ", data_quality_summary$extreme_pb,
    " | P/S: ", data_quality_summary$extreme_ps, "\n")

# ---- SECTION 8 : summary statistics -----------------------------------------
cat("Calculating summary statistics …\n")

# Summary statistics for key metrics
summary_stats <- unified_final %>%
  dplyr::filter(has_complete_dataset) %>%
  dplyr::summarise(
    avg_market_cap = round(mean(market_cap, na.rm = TRUE), 2),
    median_market_cap = round(median(market_cap, na.rm = TRUE), 2),
    avg_pe_ratio = round(mean(price_to_earnings, na.rm = TRUE), 2),
    median_pe_ratio = round(median(price_to_earnings, na.rm = TRUE), 2),
    avg_pb_ratio = round(mean(price_to_book, na.rm = TRUE), 2),
    median_pb_ratio = round(median(price_to_book, na.rm = TRUE), 2),
    avg_ps_ratio = round(mean(price_to_sales, na.rm = TRUE), 2),
    median_ps_ratio = round(median(price_to_sales, na.rm = TRUE), 2),
    avg_revenue_per_share = round(mean(revenue_per_share, na.rm = TRUE), 2),
    avg_earnings_per_share = round(mean(earnings_per_share, na.rm = TRUE), 2)
  )

cat("Summary Statistics (complete datasets only):\n")
cat(" • Market Cap - Mean: $", summary_stats$avg_market_cap, "M | Median: $", summary_stats$median_market_cap, "M\n")
cat(" • P/E Ratio - Mean: ", summary_stats$avg_pe_ratio, " | Median: ", summary_stats$median_pe_ratio, "\n")
cat(" • P/B Ratio - Mean: ", summary_stats$avg_pb_ratio, " | Median: ", summary_stats$median_pb_ratio, "\n")
cat(" • P/S Ratio - Mean: ", summary_stats$avg_ps_ratio, " | Median: ", summary_stats$median_ps_ratio, "\n")
cat(" • Revenue per Share - Mean: $", summary_stats$avg_revenue_per_share, "\n")
cat(" • Earnings per Share - Mean: $", summary_stats$avg_earnings_per_share, "\n")

# ---- SECTION 9 : save unified artifact --------------------------------------
cat("Saving unified financial artifact …\n")

output_file <- "cache/unified_financial_artifact.csv"
write.csv(
  unified_final,
  output_file,
  row.names = FALSE,
  na = ""
)

cat("Saved: ", output_file, "\n")
cat("Final dataset: ", nrow(unified_final), " rows, ", ncol(unified_final), " columns\n")

# ---- SECTION 10 : sample output display ------------------------------------
cat("\nSample data:\n")
sample_data <- unified_final %>%
  dplyr::filter(has_complete_dataset) %>%
  dplyr::select(
    ticker, date, close, market_cap,
    revenue_per_share, earnings_per_share, book_value_per_share,
    price_to_earnings, price_to_book, price_to_sales,
    data_freshness_quality
  ) %>%
  head(10)

print(sample_data)

# Show column structure
cat("\nColumn structure:\n")
cat("Total columns: ", ncol(unified_final), "\n")

# Group columns by category
price_columns <- names(unified_final)[grepl("^(open|high|low|close|adjusted|volume|dividend|split_coeff)", names(unified_final))]
market_cap_columns <- names(unified_final)[grepl("market_cap|shares_outstanding|split_multiplier", names(unified_final))]
per_share_columns <- names(unified_final)[grepl("_per_share$", names(unified_final))]
ratio_columns <- names(unified_final)[grepl("^(price_to_|ev_to_|market_cap_to_)", names(unified_final))]
quality_columns <- names(unified_final)[grepl("^(has_|valid_|extreme_|data_freshness)", names(unified_final))]

cat(" • Price data columns: ", length(price_columns), "\n")
cat(" • Market cap columns: ", length(market_cap_columns), "\n")
cat(" • Per-share metrics: ", length(per_share_columns), "\n")
cat(" • Valuation ratios: ", length(ratio_columns), "\n")
cat(" • Data quality flags: ", length(quality_columns), "\n")

# Show per-share metrics available
cat("\nPer-share metrics available:\n")
for (col in per_share_columns) {
  non_na_count <- sum(!is.na(unified_final[[col]]))
  cat(" • ", col, ": ", non_na_count, " observations\n")
}

# =============================================================================
# END OF FILE
# =============================================================================
