# avpipeline

<!-- badges: start -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.0.0.9000-blue.svg)](https://github.com/bmtnc/avpipeline)
<!-- badges: end -->

An R package that provides utilities and tools for working with Alpha Vantage API data. The package focuses on making it easier to access, validate, and process financial data from the Alpha Vantage service with caching and robust error handling.

## Features

### 🚀 Core Functionality
- **Single Ticker Data**: Fetch daily adjusted price data for individual stocks
- **Batch Processing**: Process multiple tickers with progress tracking and error handling
- **Income Statement Data**: Fetch quarterly income statement data from Alpha Vantage
- **ETF Holdings**: Retrieve ETF holdings and convert to ticker lists
- **Caching**: Avoid redundant API calls with smart cache management
- **Batch Caching**: Resilient data fetching with retry logic and comprehensive error handling

### 🛡️ Robust Infrastructure
- **API Key Management**: Secure and flexible API key handling
- **Data Validation**: Comprehensive validation with clear error messages
- **Rate Limiting**: Built-in API rate limiting compliance
- **Error Recovery**: Graceful handling of network issues and API errors
- **Progress Tracking**: Real-time progress reporting for long-running operations

### 🎯 Developer Experience
- **Consistent Interface**: Uniform function signatures across all data types
- **Clear Documentation**: Comprehensive roxygen2 documentation with examples
- **Flexible Configuration**: Works with different API key management patterns
- **R Package Standards**: Follows R package development best practices

## Installation

```r
# Install from GitHub
# install.packages("devtools")
devtools::install_github("bmtnc/avpipeline")
```

## Quick Start

### 1. Set up your Alpha Vantage API key

```r
# Option 1: Set environment variable (recommended)
Sys.setenv(ALPHA_VANTAGE_API_KEY = "your_api_key_here")

# Option 2: Pass directly to functions
api_key <- "your_api_key_here"
```

### 2. Fetch single ticker data

```r
library(avpipeline)

# Fetch recent price data for Apple
apple_data <- fetch_daily_adjusted_prices("AAPL")
head(apple_data)
```

### 3. Fetch multiple tickers with caching

```r
# Define tickers to fetch
tickers <- c("AAPL", "GOOGL", "MSFT", "AMZN")

# Fetch with caching
price_data <- fetch_multiple_with_cache_generic(
  tickers = tickers,
  output_dir = "cache",
  cache_file = "price_cache.csv",
  fetch_function = fetch_daily_adjusted_prices,
  date_columns = c("date")
)
```

### 4. Fetch income statement data

```r
# Fetch quarterly income statement data
income_data <- fetch_multiple_income_statements(
  tickers = c("AAPL", "GOOGL"),
  delay_seconds = 12  # Respect API rate limits
)
```

### 5. Get ETF holdings

```r
# Get ticker symbols from QQQ ETF
qqq_holdings <- fetch_etf_holdings("QQQ")
head(qqq_holdings)
```

## Main Functions

### Data Fetching
- `fetch_daily_adjusted_prices()` - Fetch daily OHLCV data for a single ticker
- `fetch_multiple_tickers()` - Batch process multiple tickers
- `fetch_income_statement()` - Fetch quarterly income statement for a single ticker
- `fetch_multiple_income_statements()` - Batch process multiple income statements
- `fetch_etf_holdings()` - Get ticker symbols from ETF holdings

### Caching Functions
- `fetch_multiple_with_cache_generic()` - Generic caching orchestration
- `fetch_multiple_with_incremental_cache_generic()` - Batch caching with retry logic and comprehensive error handling
- `read_cached_data()` - Generic cache reading with date conversion
- `read_cached_price_data()` - Read cached price data
- `read_cached_income_statement_data()` - Read cached income statement data

### Utility Functions
- `get_api_key()` - Secure API key management
- `validate_df_cols()` - Data validation with clear error messages
- `get_symbols_to_fetch()` - Determine which tickers need fetching vs. cached

## Usage Examples

### Basic Price Data Fetching

```r
# Fetch Apple's recent price data
apple <- fetch_daily_adjusted_prices("AAPL", outputsize = "compact")

# Fetch full historical data
apple_full <- fetch_daily_adjusted_prices("AAPL", outputsize = "full")

# View the structure
str(apple)
```

### Batch Processing with Progress Tracking

```r
# Define a list of tickers
tech_stocks <- c("AAPL", "GOOGL", "MSFT", "AMZN", "TSLA")

# Fetch all with progress tracking
results <- fetch_multiple_tickers(
  tickers = tech_stocks,
  outputsize = "compact",
  delay_seconds = 12  # Respect API rate limits
)

# The result is a single tibble with all data
nrow(results)
head(results)
```

### Caching Example

```r
# First run - fetches from API and caches
data1 <- fetch_multiple_with_cache_generic(
  tickers = c("AAPL", "GOOGL", "MSFT"),
  output_dir = "my_cache",
  cache_file = "prices.csv",
  fetch_function = fetch_daily_adjusted_prices,
  date_columns = c("date")
)

# Second run - uses cached data (much faster)
data2 <- fetch_multiple_with_cache_generic(
  tickers = c("AAPL", "GOOGL", "MSFT"),
  output_dir = "my_cache", 
  cache_file = "prices.csv",
  fetch_function = fetch_daily_adjusted_prices,
  date_columns = c("date")
)

# Add new tickers - only fetches the new ones
data3 <- fetch_multiple_with_cache_generic(
  tickers = c("AAPL", "GOOGL", "MSFT", "AMZN", "TSLA"),
  output_dir = "my_cache",
  cache_file = "prices.csv", 
  fetch_function = fetch_daily_adjusted_prices,
  date_columns = c("date")
)
```

### Income Statement Data

```r
# Fetch quarterly income statement data
income <- fetch_income_statement("AAPL")

# Batch process multiple companies
income_data <- fetch_multiple_income_statements(
  tickers = c("AAPL", "GOOGL", "MSFT"),
  delay_seconds = 12
)

# View available columns
names(income_data)
```

### ETF Holdings to Price Data Pipeline

```r
# Get ETF holdings
etf_tickers <- fetch_etf_holdings("QQQ")

# Fetch price data for all holdings
etf_prices <- fetch_multiple_with_cache_generic(
  tickers = etf_tickers,
  output_dir = "etf_cache",
  cache_file = "qqq_holdings_prices.csv",
  fetch_function = fetch_daily_adjusted_prices,
  date_columns = c("date")
)
```

## API Key Management

The package provides flexible API key management:

```r
# Method 1: Environment variable (recommended)
Sys.setenv(ALPHA_VANTAGE_API_KEY = "your_key_here")
api_key <- get_api_key()

# Method 2: Direct specification
api_key <- get_api_key("your_explicit_key")

# Method 3: Pass to individual functions
data <- fetch_daily_adjusted_prices("AAPL", api_key = "your_key_here")
```

## Error Handling

The package provides comprehensive error handling with clear messages:

```r
# Data validation example
df <- data.frame(ticker = "AAPL", price = 150)

# This will provide a clear error message
validate_df_cols(df, c("ticker", "date", "close"))
# Error: Missing required columns: date, close
# Available columns: ticker, price
```

## Caching Strategy

The package implements caching to minimize API calls:

1. **Cache Detection**: Automatically detects existing cached data
2. **Incremental Updates**: Only fetches missing tickers
3. **Data Integrity**: Validates cached data before use
4. **Resilient Writes**: Batch caching with retry logic and comprehensive failure tracking
5. **Retry Logic**: Up to 3 attempts per ticker with escalating delays (5s, 10s)
6. **Failure Reporting**: Detailed error messages for failed tickers

## Rate Limiting

Alpha Vantage API has rate limits. The package handles this automatically:

- **Free Tier**: 5 API calls per minute, 500 per day
- **Built-in Delays**: Configurable delays between requests
- **Progress Tracking**: Shows progress during long-running operations

## Development Status

This package is currently in development (version 0.0.0.9000). Features implemented:

- ✅ Single ticker price data fetching
- ✅ Multiple ticker batch processing
- ✅ caching system
- ✅ Incremental caching for resilience
- ✅ Income statement data fetching
- ✅ ETF holdings integration
- ✅ Generic caching architecture
- ✅ Comprehensive error handling
- ✅ API key management
- ✅ Data validation utilities

### Planned Features
- Balance sheet data fetching
- Cash flow statement data fetching
- Enhanced test coverage
- Performance optimizations
- Additional data validation utilities

## Contributing

This package follows standard R package development practices:

1. Use `renv` for dependency management
2. Follow tidyverse style guidelines
3. Include comprehensive documentation
4. Add tests for new functionality
5. Update NEWS.md for changes

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Getting Help

- **Documentation**: All functions include comprehensive help documentation
- **Examples**: See function documentation for usage examples

## Alpha Vantage API

This package requires an Alpha Vantage API key. Get your free API key at [Alpha Vantage](https://www.alphavantage.co/support/#api-key).

### API Endpoints Used
- `TIME_SERIES_DAILY_ADJUSTED` - Daily price data
- `INCOME_STATEMENT` - Quarterly income statement data  
- `ETF_PROFILE` - ETF holdings and profile data

---

**Disclaimer**: This package is not affiliated with Alpha Vantage. Please review Alpha Vantage's terms of service before using their API.
