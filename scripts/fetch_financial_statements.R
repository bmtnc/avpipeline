# Unified Financial Artifacts Data Fetcher
# Fetches quarterly financial data for multiple tickers across all four data types
# Uses configuration-based architecture with helper functions for maintainability

# ==============================================================================
# CONFIGURATION
# ==============================================================================
etf_symbol <- "IWB"

# Alternative: Use manually curated tickers if needed
# manual_tickers <- c("URI", "XOM")

# ==============================================================================
# FETCH TICKERS
# ==============================================================================
tickers <- get_financial_statement_tickers(etf_symbol = etf_symbol)

# ==============================================================================
# FETCH ALL FINANCIAL STATEMENTS
# ==============================================================================
cache_paths <- get_financial_cache_paths()
fetch_all_financial_statements(tickers, cache_paths)

# ==============================================================================
# LOAD CACHED DATA
# ==============================================================================
data <- load_all_financial_statements(cache_paths)
bs <- data$balance_sheet
cf <- data$cash_flow
is <- data$income_statement
meta <- data$earnings

# ==============================================================================
# SUMMARY
# ==============================================================================
summarize_financial_data_fetch(etf_symbol, tickers, data)
