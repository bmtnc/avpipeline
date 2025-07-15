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
etf_symbol <- "XLK"  # Can be changed to any ETF (e.g., "SPY", "VTI", "IWM")

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
# HELPER FUNCTION: FETCH WITH SMART CACHING
# ==============================================================================
fetch_with_smart_caching <- function(data_type_name, cache_file, config, tickers) {
  cat("\n=== Processing", data_type_name, "Data ===\n")
  
  # Step 1: Read existing cache if it exists
  existing_data <- NULL
  if (file.exists(cache_file)) {
    existing_data <- read_cached_data(cache_file, date_columns = config$cache_date_columns)
    cat("Existing cache found with", nrow(existing_data), "rows\n")
  } else {
    cat("No existing cache found\n")
  }
  
  # Step 2: Determine which tickers need to be fetched
  tickers_to_fetch <- get_symbols_to_fetch(tickers, existing_data, symbol_column = "ticker")
  
  cat("Tickers already in cache:", length(tickers) - length(tickers_to_fetch), "\n")
  cat("Tickers to fetch:", length(tickers_to_fetch), "\n")
  
  # Step 3: Only fetch if there are missing tickers
  if (length(tickers_to_fetch) > 0) {
    cat("Fetching data for", length(tickers_to_fetch), "missing tickers...\n")
    
    fetch_multiple_with_incremental_cache_generic(
      tickers = tickers_to_fetch,
      cache_file = cache_file,
      single_fetch_func = function(ticker, ...) {
        fetch_alpha_vantage_data(ticker, config, ...)
      },
      cache_reader_func = function(cache_file) {
        read_cached_data(cache_file, date_columns = config$cache_date_columns)
      },
      data_type_name = config$data_type_name,
      delay_seconds = config$default_delay
    )
  } else {
    cat("All tickers already in cache - skipping API calls\n")
  }
  
  return(invisible(TRUE))
}

# ==============================================================================
# FETCH BALANCE SHEET DATA
# ==============================================================================
fetch_with_smart_caching(
  data_type_name = "Balance Sheet",
  cache_file = balance_sheet_cache,
  config = BALANCE_SHEET_CONFIG,
  tickers = tickers
)

# ==============================================================================
# FETCH CASH FLOW DATA
# ==============================================================================
fetch_with_smart_caching(
  data_type_name = "Cash Flow",
  cache_file = cash_flow_cache,
  config = CASH_FLOW_CONFIG,
  tickers = tickers
)

# ==============================================================================
# FETCH INCOME STATEMENT DATA
# ==============================================================================
fetch_with_smart_caching(
  data_type_name = "Income Statement",
  cache_file = income_statement_cache,
  config = INCOME_STATEMENT_CONFIG,
  tickers = tickers
)

# ==============================================================================
# FETCH EARNINGS DATA
# ==============================================================================
fetch_with_smart_caching(
  data_type_name = "Earnings",
  cache_file = earnings_cache,
  config = EARNINGS_CONFIG,
  tickers = tickers
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
