# Alpha Vantage Splits Data Fetcher
# Fetches historical stock split events for multiple tickers and returns long-format dataframe
# Uses configuration-based architecture with intelligent caching
# Supports incremental updates - only fetches data for tickers not already cached

# Load package functions
devtools::load_all()

# Check if required cache directories exist
if (!dir.exists("cache")) {
  dir.create("cache")
}

# Define cache file path
cache_file <- "cache/splits_artifact.csv"

# Load existing financial statements and price data to determine ticker universe
cat("Loading existing artifacts to determine ticker universe...\n")

# Load financial statements artifact
financial_statements <- read_cached_data("cache/financial_statements_artifact.csv", 
                                        date_columns = c("fiscalDateEnding", "reportedDate", "as_of_date"))

# Load price artifact
prices <- read_cached_data("cache/price_artifact.csv", 
                          date_columns = PRICE_CONFIG$cache_date_columns)

# Define ticker universe as intersection of both datasets
financial_tickers <- unique(financial_statements$ticker)
price_tickers <- unique(prices$ticker)
target_tickers <- intersect(financial_tickers, price_tickers)

cat("Ticker universe definition:\n")
cat("- Financial statements tickers:", length(financial_tickers), "\n")
cat("- Price data tickers:", length(price_tickers), "\n")
cat("- Target universe (intersection):", length(target_tickers), "\n")

if (length(target_tickers) == 0) {
  stop("No common tickers found between financial statements and price data")
}

# Fetch splits data with intelligent caching using configuration-based approach
cat("Fetching splits data with intelligent caching...\n")

splits_data <- fetch_multiple_tickers_with_cache(
  tickers = target_tickers,
  cache_file = cache_file,
  single_fetch_func = function(ticker, ...) {
    fetch_single_ticker_data(ticker, SPLITS_CONFIG, ...)
  },
  cache_reader_func = function(cache_file) {
    read_cached_data(cache_file, date_columns = SPLITS_CONFIG$cache_date_columns)
  },
  data_type_name = SPLITS_CONFIG$data_type_name,
  delay_seconds = SPLITS_CONFIG$default_delay
)

# Load the final cached data
splits_final <- read_cached_data(cache_file, date_columns = SPLITS_CONFIG$cache_date_columns)

# Generate summary statistics
cat("Splits artifact summary:\n")
cat("- Total tickers in cache:", length(unique(splits_final$ticker)), "\n")
cat("- Total split events:", nrow(splits_final), "\n")

if (nrow(splits_final) > 0) {
  cat("- Date range:", as.character(min(splits_final$effective_date)), "to", 
      as.character(max(splits_final$effective_date)), "\n")
  
  # Summary by ticker
  splits_summary <- splits_final %>%
    dplyr::group_by(ticker) %>%
    dplyr::summarise(
      split_events = dplyr::n(),
      earliest_split = min(effective_date),
      latest_split = max(effective_date),
      .groups = "drop"
    ) %>%
    dplyr::arrange(dplyr::desc(split_events))
  
  cat("- Tickers with splits:", nrow(splits_summary), "\n")
  cat("- Most active splitters:\n")
  print(head(splits_summary, 10))
  
  # Show example splits
  cat("- Sample split events:\n")
  print(head(splits_final %>% dplyr::arrange(dplyr::desc(effective_date)), 10))
} else {
  cat("- No split events found in the dataset\n")
}

cat("Splits artifact saved successfully!\n")
cat("Output file: cache/splits_artifact.csv\n")
