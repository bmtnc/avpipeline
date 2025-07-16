# Alpha Vantage Daily Adjusted Price Data Fetcher
# Fetches daily price data for multiple tickers and returns long-format dataframe
# Uses new configuration-based architecture for cleaner, more maintainable code
# Now dynamically fetches tickers from ETF holdings via Alpha Vantage API

# Load package functions
devtools::load_all()

# Define ETF symbol to fetch holdings from
etf_symbol <- "SPY"  # Can be changed to any ETF (e.g., "SPY", "VTI", "IWM")

# Fetch tickers from ETF holdings
cat("Fetching holdings for ETF:", etf_symbol, "\n")
tickers <- fetch_etf_holdings(etf_symbol)

# Alternative: Use manually curated tickers if needed
# tickers <- c("URI", "XOM")

# Define cache file path
cache_file <- "cache/price_artifact.csv"

# Fetch data with intelligent caching using configuration-based approach
price_object <- fetch_multiple_tickers_with_cache(
  tickers = tickers,
  cache_file = cache_file,
  single_fetch_func = function(ticker, ...) {
    fetch_single_ticker_data(ticker, PRICE_CONFIG, ...)
  },
  cache_reader_func = function(cache_file) {
    read_cached_data(cache_file, date_columns = PRICE_CONFIG$cache_date_columns)
  },
  data_type_name = PRICE_CONFIG$data_type_name,
  delay_seconds = PRICE_CONFIG$default_delay,
  outputsize = "full",  # "compact" for latest 100 days, "full" for 20+ years
  datatype = "json"
)


prices <- read_cached_data(cache_file, date_columns = PRICE_CONFIG$cache_date_columns)
