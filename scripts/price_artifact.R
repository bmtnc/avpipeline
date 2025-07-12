# Alpha Vantage Daily Adjusted Price Data Fetcher
# Fetches daily price data for multiple tickers and returns long-format dataframe
# Uses new caching helper functions for cleaner, more maintainable code
# Now dynamically fetches tickers from ETF holdings via Alpha Vantage API

# Load package functions
devtools::load_all()

# Define ETF symbol to fetch holdings from
etf_symbol <- "QQQ"  # Can be changed to any ETF (e.g., "SPY", "VTI", "IWM")

# Fetch tickers from ETF holdings
cat("Fetching holdings for ETF:", etf_symbol, "\n")
tickers <- fetch_etf_holdings(etf_symbol)

# Alternative: Use manually curated tickers if needed
# tickers <- c("IBM", "AAPL", "MSFT", "GOOGL", "TSLA", "NVDA", "AMZN", "META")

# Define cache file path
cache_file <- "cache/price_artifact.csv"

# Fetch data with intelligent caching
price_object <- fetch_multiple_tickers_with_cache(
  tickers = tickers,
  cache_file = cache_file,
  outputsize = "full",  # "compact" for latest 100 days, "full" for 20+ years
  datatype = "json"
)
