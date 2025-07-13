# Alpha Vantage Balance Sheet Data Fetcher
# Fetches quarterly balance sheet data for multiple tickers and returns long-format dataframe
# Uses new configuration-based architecture for cleaner, more maintainable code
# Now dynamically fetches tickers from ETF holdings via Alpha Vantage API

# Load package functions
devtools::load_all()

# Define ETF symbol to fetch holdings from
etf_symbol <- "qqq"  # Can be changed to any ETF (e.g., "SPY", "VTI", "IWM")

# Fetch tickers from ETF holdings
cat("Fetching holdings for ETF:", etf_symbol, "\n")
tickers <- fetch_etf_holdings(etf_symbol)

# Alternative: Use manually curated tickers if needed
# tickers <- c("URI", "XOM")

# Define cache file path
cache_file <- "cache/balance_sheet_artifact.csv"

# Fetch data with intelligent caching using configuration-based approach
balance_sheet_object <- fetch_multiple_with_incremental_cache_generic(
  tickers = tickers,
  cache_file = cache_file,
  single_fetch_func = function(ticker, ...) {
    fetch_alpha_vantage_data(ticker, BALANCE_SHEET_CONFIG, ...)
  },
  cache_reader_func = function(cache_file) {
    read_cached_data(cache_file, date_columns = BALANCE_SHEET_CONFIG$cache_date_columns)
  },
  data_type_name = BALANCE_SHEET_CONFIG$data_type_name,
  delay_seconds = BALANCE_SHEET_CONFIG$default_delay
)


bs <- read_cached_data(cache_file, date_columns = BALANCE_SHEET_CONFIG$cache_date_columns)
