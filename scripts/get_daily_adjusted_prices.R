# Alpha Vantage Daily Adjusted Price Data Fetcher
# Fetches daily price data for multiple tickers and returns long-format dataframe

# Define tickers to fetch
tickers <- c("IBM", "AAPL", "MSFT", "GOOGL", "TSLA")

# Fetch daily adjusted price data for all tickers
price_data <- fetch_multiple_tickers(
  tickers = tickers,
  outputsize = "compact",  # "compact" for latest 100 days, "full" for 20+ years
  datatype = "json"
)

# Display results
cat("Data fetched successfully!\n")
cat("Shape:", nrow(price_data), "rows x", ncol(price_data), "columns\n")
cat("Date range:", as.character(min(price_data$date)), "to", as.character(max(price_data$date)), "\n")
cat("Tickers:", paste(unique(price_data$ticker), collapse = ", "), "\n")

# Preview the data structure
print(head(price_data))

# Summary by ticker
ticker_summary <- price_data %>%
  dplyr::group_by(ticker) %>%
  dplyr::summarise(
    rows = dplyr::n(),
    date_range = paste(min(date), "to", max(date)),
    avg_close = round(mean(close, na.rm = TRUE), 2),
    .groups = "drop"
  )

cat("\nSummary by ticker:\n")
print(ticker_summary)
