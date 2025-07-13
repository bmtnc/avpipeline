# Alpha Vantage Equities Artifact Creator
# Combines price data with financial statements using earnings timing metadata
# Creates comprehensive point-in-time dataset where each daily price observation
# includes the most recent financial information available to markets at that date

# Load package functions
devtools::load_all()

# Load all required artifacts
cat("Loading price data...\n")
prices <- read_cached_data("cache/price_artifact.csv", date_columns = c("date", "initial_date", "latest_date", "as_of_date"))

cat("Loading financial statement data...\n")
is <- read_cached_data("cache/income_statement_artifact.csv", date_columns = c("fiscalDateEnding", "as_of_date"))
bs <- read_cached_data("cache/balance_sheet_artifact.csv", date_columns = c("fiscalDateEnding", "as_of_date"))
cf <- read_cached_data("cache/cash_flow_artifact.csv", date_columns = c("fiscalDateEnding", "as_of_date"))
meta <- read_cached_data("cache/earnings_artifact.csv", date_columns = c("fiscalDateEnding", "reportedDate", "as_of_date"))

# Validate that we have data for all artifacts
if (nrow(prices) == 0) stop("No price data found")
if (nrow(meta) == 0) stop("No earnings metadata found")
if (nrow(is) == 0) stop("No income statement data found")
if (nrow(bs) == 0) stop("No balance sheet data found")
if (nrow(cf) == 0) stop("No cash flow data found")

cat("Data loaded successfully:\n")
cat("- Prices:", nrow(prices), "observations\n")
cat("- Income statements:", nrow(is), "observations\n")
cat("- Balance sheets:", nrow(bs), "observations\n")
cat("- Cash flows:", nrow(cf), "observations\n")
cat("- Earnings metadata:", nrow(meta), "observations\n")

# Step 1: Join financial statements with metadata
cat("Joining financial statements with earnings metadata...\n")
financial_statements <- meta %>%
  dplyr::left_join(is, by = c("ticker", "fiscalDateEnding"), suffix = c("", ".is")) %>%
  dplyr::left_join(bs, by = c("ticker", "fiscalDateEnding"), suffix = c("", ".bs")) %>%
  dplyr::left_join(cf, by = c("ticker", "fiscalDateEnding"), suffix = c("", ".cf")) %>%
  # Clean up duplicate columns - keep the original from meta, remove suffixed duplicates
  dplyr::select(-dplyr::any_of(c("as_of_date.is", "as_of_date.bs", "as_of_date.cf", 
                                 "reportedCurrency.is", "reportedCurrency.bs", "reportedCurrency.cf"))) %>%
  dplyr::arrange(ticker, fiscalDateEnding)

# Step 2: Create business date bridge for reportedDate alignment
# Handle cases where reportedDate falls on weekends/holidays
cat("Creating business date bridge...\n")
financial_statements <- financial_statements %>%
  dplyr::mutate(
    # Use reportedDate as the key for joining with price data
    join_date = reportedDate
  ) %>%
  dplyr::filter(!is.na(join_date)) %>%
  dplyr::arrange(ticker, join_date)

# Step 3: Join with price data using date logic
cat("Joining financial data with price data...\n")

# First, create a comprehensive ticker-date grid from price data
price_dates <- prices %>%
  dplyr::select(ticker, date) %>%
  dplyr::arrange(ticker, date)

# Perform a rolling join to match each price date with the most recent financial data
equities_artifact <- price_dates %>%
  # Add price data
  dplyr::left_join(prices, by = c("ticker", "date")) %>%
  # Use a rolling join approach: for each ticker-date, find the most recent financial data
  dplyr::group_by(ticker) %>%
  dplyr::arrange(ticker, date) %>%
  # Create a helper to track the most recent financial data available
  dplyr::left_join(
    financial_statements %>%
      dplyr::rename(financial_as_of_date = as_of_date),
    by = c("ticker"),
    relationship = "many-to-many"
  ) %>%
  # Keep only financial data that was available on or before the price date
  dplyr::filter(is.na(join_date) | join_date <= date) %>%
  # For each ticker-date, keep only the most recent financial data
  dplyr::group_by(ticker, date) %>%
  dplyr::arrange(ticker, date, dplyr::desc(join_date)) %>%
  dplyr::slice(1) %>%
  dplyr::ungroup()

# Step 4: Forward fill financial data within each ticker
cat("Forward filling financial data...\n")
equities_artifact <- equities_artifact %>%
  dplyr::arrange(ticker, date) %>%
  dplyr::group_by(ticker) %>%
  # Forward fill key financial metrics
  tidyr::fill(
    # Metadata
    fiscalDateEnding, reportedDate, reportTime, join_date, financial_as_of_date,
    # Income statement
    totalRevenue, grossProfit, operatingIncome, netIncome, ebit, ebitda,
    # Balance sheet  
    totalAssets, totalCurrentAssets, cashAndCashEquivalentsAtCarryingValue,
    totalLiabilities, totalCurrentLiabilities, totalShareholderEquity,
    # Cash flow
    operatingCashflow, cashflowFromInvestment, cashflowFromFinancing,
    # Currency
    reportedCurrency,
    .direction = "down"
  ) %>%
  dplyr::ungroup()

# Step 5: Clean and validate final dataset
cat("Cleaning and validating final dataset...\n")
equities_artifact <- equities_artifact %>%
  # Remove helper columns
  dplyr::select(-join_date) %>%
  # Ensure proper ordering
  dplyr::arrange(ticker, date) %>%
  # Add data quality indicators
  dplyr::mutate(
    has_financial_data = !is.na(fiscalDateEnding),
    days_since_earnings = ifelse(is.na(reportedDate), NA, as.numeric(date - reportedDate))
  )

# Step 6: Summary statistics and validation
cat("Final dataset summary:\n")
cat("- Total observations:", nrow(equities_artifact), "\n")
cat("- Unique tickers:", length(unique(equities_artifact$ticker)), "\n")
cat("- Date range:", min(equities_artifact$date), "to", max(equities_artifact$date), "\n")
cat("- Observations with financial data:", sum(equities_artifact$has_financial_data, na.rm = TRUE), "\n")
cat("- Financial data coverage:", round(100 * mean(equities_artifact$has_financial_data, na.rm = TRUE), 1), "%\n")

# Save the final artifact
cache_file <- "cache/equities_artifact.csv"
cat("Saving equities artifact to:", cache_file, "\n")
write.csv(equities_artifact, cache_file, row.names = FALSE)

cat("Equities artifact created successfully!\n")
