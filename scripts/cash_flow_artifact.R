# Alpha Vantage Cash Flow Data Fetcher
# Fetches quarterly cash flow statement data for multiple tickers and returns long-format dataframe
# Uses new configuration-based architecture for cleaner, more maintainable code
# Now dynamically fetches tickers from ETF holdings via Alpha Vantage API

# Load package functions
devtools::load_all()

# Define ETF symbol to fetch holdings from
etf_symbol <- "QQQ"  # Can be changed to any ETF (e.g., "SPY", "VTI", "IWM")

# Fetch tickers from ETF holdings
cat("Fetching holdings for ETF:", etf_symbol, "\n")
tickers <- fetch_etf_holdings(etf_symbol)

# Alternative: Use manually curated tickers if needed
# tickers <- c("URI", "XOM")

# Define cache file path
cache_file <- "cache/cash_flow_artifact.csv"

# Fetch data with intelligent caching using configuration-based approach
cash_flow_object <- fetch_multiple_tickers_with_cache(
  tickers = tickers,
  cache_file = cache_file,
  single_fetch_func = function(ticker, ...) {
    fetch_single_ticker_data(ticker, CASH_FLOW_CONFIG, ...)
  },
  cache_reader_func = function(cache_file) {
    read_cached_data(cache_file, date_columns = CASH_FLOW_CONFIG$cache_date_columns)
  },
  data_type_name = CASH_FLOW_CONFIG$data_type_name,
  delay_seconds = CASH_FLOW_CONFIG$default_delay
)


cf <- read_cached_data(cache_file, date_columns = CASH_FLOW_CONFIG$cache_date_columns)
