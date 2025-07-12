# Alpha Vantage Income Statement Data Fetcher
# Fetches quarterly income statement data for multiple tickers and returns long-format dataframe
# Uses new caching helper functions for cleaner, more maintainable code
# Now dynamically fetches tickers from ETF holdings via Alpha Vantage API

# Load package functions
devtools::load_all()

# Define ETF symbol to fetch holdings from
etf_symbol <- "XLK"  # Can be changed to any ETF (e.g., "SPY", "VTI", "IWM")

# Fetch tickers from ETF holdings
cat("Fetching holdings for ETF:", etf_symbol, "\n")
tickers <- fetch_etf_holdings(etf_symbol)

# Alternative: Use manually curated tickers if needed
tickers <- c("ENTG", "ASML")

# Define cache file path
cache_file <- "cache/income_statement_artifact.csv"

# Fetch data with intelligent caching
income_statement_object <- fetch_multiple_income_statements_with_cache(
  tickers = tickers,
  cache_file = cache_file
)
