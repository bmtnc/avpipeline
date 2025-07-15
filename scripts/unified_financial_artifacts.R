# Unified Financial Artifacts Data Fetcher
# Combines functionality from balance_sheet_artifact.R, cash_flow_artifact.R, 
# income_statement_artifact.R, and earnings_artifact.R into one script
# Fetches quarterly financial data for multiple tickers across all four data types
# Uses configuration-based architecture for cleaner, more maintainable code

# Load package functions
devtools::load_all()

# ==============================================================================
# CONFIGURATION - Change this to fetch holdings from different ETFs
# ==============================================================================
etf_symbol <- "SOXX"  # Can be changed to any ETF (e.g., "SPY", "VTI", "IWM")

# ==============================================================================
# FETCH ETF HOLDINGS
# ==============================================================================
cat("Fetching holdings for ETF:", etf_symbol, "\n")
tickers <- fetch_etf_holdings(etf_symbol)

# Alternative: Use manually curated tickers if needed
# tickers <- c("URI", "XOM")

cat("Total tickers from ETF:", length(tickers), "\n")

# ==============================================================================
# DEFINE CACHE FILE PATHS
# ==============================================================================
balance_sheet_cache <- "cache/balance_sheet_artifact.csv"
cash_flow_cache <- "cache/cash_flow_artifact.csv"
income_statement_cache <- "cache/income_statement_artifact.csv"
earnings_cache <- "cache/earnings_artifact.csv"

# ==============================================================================
# FETCH BALANCE SHEET DATA
# ==============================================================================
cat("\n=== Processing Balance Sheet Data ===\n")
fetch_multiple_with_incremental_cache_generic(
  tickers = tickers,
  cache_file = balance_sheet_cache,
  single_fetch_func = function(ticker, ...) {
    fetch_alpha_vantage_data(ticker, BALANCE_SHEET_CONFIG, ...)
  },
  cache_reader_func = function(cache_file) {
    read_cached_data(cache_file, date_columns = BALANCE_SHEET_CONFIG$cache_date_columns)
  },
  data_type_name = BALANCE_SHEET_CONFIG$data_type_name,
  delay_seconds = BALANCE_SHEET_CONFIG$default_delay
)

# ==============================================================================
# FETCH CASH FLOW DATA
# ==============================================================================
cat("\n=== Processing Cash Flow Data ===\n")
fetch_multiple_with_incremental_cache_generic(
  tickers = tickers,
  cache_file = cash_flow_cache,
  single_fetch_func = function(ticker, ...) {
    fetch_alpha_vantage_data(ticker, CASH_FLOW_CONFIG, ...)
  },
  cache_reader_func = function(cache_file) {
    read_cached_data(cache_file, date_columns = CASH_FLOW_CONFIG$cache_date_columns)
  },
  data_type_name = CASH_FLOW_CONFIG$data_type_name,
  delay_seconds = CASH_FLOW_CONFIG$default_delay
)

# ==============================================================================
# FETCH INCOME STATEMENT DATA
# ==============================================================================
cat("\n=== Processing Income Statement Data ===\n")
fetch_multiple_with_incremental_cache_generic(
  tickers = tickers,
  cache_file = income_statement_cache,
  single_fetch_func = function(ticker, ...) {
    fetch_alpha_vantage_data(ticker, INCOME_STATEMENT_CONFIG, ...)
  },
  cache_reader_func = function(cache_file) {
    read_cached_data(cache_file, date_columns = INCOME_STATEMENT_CONFIG$cache_date_columns)
  },
  data_type_name = INCOME_STATEMENT_CONFIG$data_type_name,
  delay_seconds = INCOME_STATEMENT_CONFIG$default_delay
)

# ==============================================================================
# FETCH EARNINGS DATA
# ==============================================================================
cat("\n=== Processing Earnings Data ===\n")
fetch_multiple_with_incremental_cache_generic(
  tickers = tickers,
  cache_file = earnings_cache,
  single_fetch_func = function(ticker, ...) {
    fetch_alpha_vantage_data(ticker, EARNINGS_CONFIG, ...)
  },
  cache_reader_func = function(cache_file) {
    read_cached_data(cache_file, date_columns = EARNINGS_CONFIG$cache_date_columns)
  },
  data_type_name = EARNINGS_CONFIG$data_type_name,
  delay_seconds = EARNINGS_CONFIG$default_delay
)

# ==============================================================================
# LOAD CACHED DATA
# ==============================================================================
cat("\n=== Loading Cached Data ===\n")

# Load balance sheet data
bs <- read_cached_data(balance_sheet_cache, date_columns = BALANCE_SHEET_CONFIG$cache_date_columns)
cat("Balance Sheet data loaded:", nrow(bs), "rows\n")

# Load cash flow data
cf <- read_cached_data(cash_flow_cache, date_columns = CASH_FLOW_CONFIG$cache_date_columns)
cat("Cash Flow data loaded:", nrow(cf), "rows\n")

# Load income statement data
is <- read_cached_data(income_statement_cache, date_columns = INCOME_STATEMENT_CONFIG$cache_date_columns)
cat("Income Statement data loaded:", nrow(is), "rows\n")

# Load earnings data
meta <- read_cached_data(earnings_cache, date_columns = EARNINGS_CONFIG$cache_date_columns)
cat("Earnings data loaded:", nrow(meta), "rows\n")

# ==============================================================================
# SUMMARY
# ==============================================================================
cat("\n=== Summary ===\n")
cat("ETF Symbol:", etf_symbol, "\n")
cat("Number of tickers processed:", length(tickers), "\n")
cat("Data types fetched: Balance Sheet, Cash Flow, Income Statement, Earnings\n")
cat("Cache files updated in cache/ directory\n")
cat("\nAvailable data objects:\n")
cat("- bs: Balance Sheet data\n")
cat("- cf: Cash Flow data\n")
cat("- is: Income Statement data\n")
cat("- meta: Earnings data\n")