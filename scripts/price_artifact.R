# Alpha Vantage Daily Adjusted Price Data Fetcher
# Fetches daily price data for multiple tickers and returns long-format dataframe
# Uses new caching helper functions for cleaner, more maintainable code

# Load package functions
devtools::load_all()

# Define tickers to fetch
tickers <- c("IBM", "AAPL", "MSFT", "GOOGL", "TSLA", "NVDA", "AMZN", "META")

# Define cache file path
cache_file <- "cache/price_artifact.csv"

# Fetch data with intelligent caching
price_object <- fetch_multiple_tickers_with_cache(
  tickers = tickers,
  cache_file = cache_file,
  outputsize = "full",  # "compact" for latest 100 days, "full" for 20+ years
  datatype = "json"
)
