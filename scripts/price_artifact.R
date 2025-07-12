# Alpha Vantage Daily Adjusted Price Data Fetcher
# Fetches daily price data for multiple tickers and returns long-format dataframe
# Uses new caching helper functions for cleaner, more maintainable code
# Now dynamically fetches tickers from ETF holdings via Alpha Vantage API

# Load package functions
devtools::load_all()

# Define ETF symbol to fetch holdings from
etf_symbol <- "XLC"  # Can be changed to any ETF (e.g., "SPY", "VTI", "IWM")

# Fetch tickers from ETF holdings
cat("Fetching holdings for ETF:", etf_symbol, "\n")
tickers <- fetch_etf_holdings(etf_symbol)

# Alternative: Use manually curated tickers if needed
tickers <- c("KKR", "APO")

# Define cache file path
cache_file <- "cache/price_artifact.csv"

# Fetch data with intelligent caching using generic function
price_object <- fetch_multiple_with_cache_generic(
  tickers = tickers,
  cache_file = cache_file,
  cache_reader_func = read_cached_price_data,
  incremental_cache_func = function(tickers, cache_file, ...) {
    fetch_multiple_with_incremental_cache_generic(
      tickers = tickers,
      cache_file = cache_file,
      single_fetch_func = fetch_daily_adjusted_prices,
      cache_reader_func = read_cached_price_data,
      data_type_name = "price",
      delay_seconds = 1,
      ...
    )
  },
  data_type_name = "price",
  outputsize = "full",  # "compact" for latest 100 days, "full" for 20+ years
  datatype = "json"
)
