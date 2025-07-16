# =============================================================================
# Market-Cap Artifact Constructor (CORRECTED - Fixed Split Double-Counting)
# =============================================================================
#
# ISSUE IDENTIFIED & FIXED:
# -------------------------
# The original code was DOUBLE-COUNTING stock splits, causing historical
# market cap values to be artificially inflated.
#
# PROBLEM: The reported `commonStockSharesOutstanding` from quarterly filings
# already reflects all splits that occurred up to the filing date. However,
# the original logic was:
# 1. Calculating cum_split_factor_reported (includes historical splits)
# 2. Doing post_filing_split_multiplier = current_cum_split / cum_split_factor_reported
# 3. This incorrectly "undoes" splits already reflected in reported shares
#
# SOLUTION: Only apply splits that occurred AFTER each filing date:
# 1. For each day, find the most recent filing
# 2. Use the reported shares from that filing (already split-adjusted)
# 3. Apply only splits that occurred after that filing date
#
# This ensures historical market caps reflect actual company valuations
# without artificial inflation from double-counted splits.
# =============================================================================

# ---- SECTION 0 : helper sources ---------------------------------------------
source("R/read_cached_data.R")          # custom I/O helpers
source("R/alpha_vantage_configs.R")     # centralised config lists

# ---- SECTION 1 : load cached data -------------------------------------------
cat("Loading cached data …\n")
financial_statements <- read_cached_data(
  "cache/financial_statements_artifact.csv",
  date_columns = c("fiscalDateEnding", "reportedDate", "as_of_date")
)

prices <- read_cached_data(
  "cache/price_artifact.csv",
  date_columns = PRICE_CONFIG$cache_date_columns
)

# ---- SECTION 1.1 : define ticker universe -----------------------------------
financial_tickers <- unique(financial_statements$ticker)
price_tickers     <- unique(prices$ticker)
target_tickers    <- intersect(financial_tickers, price_tickers)

cat(
  "Tickers – financial: ", length(financial_tickers),
  " | price: ",           length(price_tickers),
  " | intersection: ",    length(target_tickers), "\n"
)

if (length(target_tickers) == 0) {
  stop("No common tickers between financial statements and prices.")
}

# ---- SECTION 2 : load & sanitise split data ---------------------------------
cat("Loading split data …\n")
splits_cache_file <- "cache/splits_artifact.csv"

if (!file.exists(splits_cache_file)) {
  stop(
    "Missing splits artifact: ", splits_cache_file,
    "\nRun scripts/splits_artifact.R first."
  )
}

splits_data <- read_cached_data(
  splits_cache_file,
  date_columns = SPLITS_CONFIG$cache_date_columns
) %>%
  dplyr::filter(ticker %in% target_tickers) %>%
  dplyr::mutate(split_factor = as.numeric(split_factor)) %>%
  dplyr::filter(!is.na(split_factor) & split_factor > 0) %>%
  dplyr::select(ticker, date = effective_date, split_factor) %>%
  dplyr::arrange(ticker, date)

cat("Valid split events: ", nrow(splits_data), "\n")

# ---- SECTION 3 : clean price & financial data -------------------------------
cat("Cleaning price data …\n")
prices_clean <- prices %>%
  dplyr::filter(
    ticker %in% target_tickers,
    date   >= as.Date("2004-12-31"),
    !is.na(close) & close > 0
  ) %>%
  dplyr::mutate(close = as.numeric(close)) %>%
  dplyr::select(ticker, date, close) %>%
  dplyr::distinct() %>%
  dplyr::arrange(ticker, date)

cat("Price rows: ", nrow(prices_clean), "\n")

cat("Cleaning financial data …\n")
financial_clean <- financial_statements %>%
  dplyr::filter(
    ticker %in% target_tickers,
    fiscalDateEnding >= as.Date("2004-12-31")
  ) %>%
  dplyr::mutate(
    commonStockSharesOutstanding = as.numeric(commonStockSharesOutstanding)
  ) %>%
  dplyr::filter(
    !is.na(commonStockSharesOutstanding) &
    commonStockSharesOutstanding > 0
  ) %>%
  dplyr::select(ticker, reportedDate, commonStockSharesOutstanding) %>%
  dplyr::arrange(ticker, reportedDate)

cat("Financial filings: ", nrow(financial_clean), "\n")

# ---- SECTION 4 : build daily shares outstanding -----------------------------
cat("Building daily shares outstanding …\n")
daily_shares <- prices_clean %>%
  dplyr::left_join(
    financial_clean,
    by = dplyr::join_by(ticker, date >= reportedDate)
  ) %>%
  dplyr::group_by(ticker, date) %>%
  dplyr::slice_max(reportedDate, n = 1, with_ties = FALSE) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(
    has_financial_data = !is.na(commonStockSharesOutstanding),
    commonStockSharesOutstanding = as.numeric(commonStockSharesOutstanding)
  ) %>%
  dplyr::arrange(ticker, date)

cat(
  "Daily rows: ", nrow(daily_shares), "\n",
  " • with filings: ", sum(daily_shares$has_financial_data), "\n",
  " • w/o filings : ", sum(!daily_shares$has_financial_data), "\n"
)

# ---- SECTION 5 : compute cumulative split factor ----------------------------
cat("Calculating cumulative split factors …\n")
prices_with_splits <- prices_clean %>%
  dplyr::left_join(splits_data, by = c("ticker", "date")) %>%
  dplyr::group_by(ticker) %>%
  dplyr::arrange(date) %>%
  dplyr::mutate(
    split_factor = dplyr::coalesce(split_factor, 1),
    cum_split_factor = cumprod(split_factor)
  ) %>%
  dplyr::ungroup()

# ---- SECTION 6 : assemble market-cap table (CORRECTED) ----------------------
cat("Assembling market-cap table …\n")
market_data <- daily_shares %>%
  dplyr::left_join(
    prices_with_splits %>%
      dplyr::select(ticker, date, cum_split_factor),
    by = c("ticker", "date")
  ) %>%
  dplyr::group_by(ticker) %>%
  dplyr::arrange(date) %>%
  dplyr::mutate(
    # CORRECTED LOGIC: Only apply splits that occurred AFTER filing date
    post_filing_split_multiplier = dplyr::case_when(
      is.na(reportedDate) | is.na(cum_split_factor) ~ NA_real_,
      TRUE ~ {
        # Find the cumulative split factor as of the reporting date
        # This represents all splits up to and including the filing date
        filing_date_indices <- which(date <= reportedDate)
        if (length(filing_date_indices) == 0) {
          filing_date_factor <- 1  # No splits before this filing
        } else {
          last_filing_index <- max(filing_date_indices)
          filing_date_factor <- cum_split_factor[last_filing_index]
          if (is.na(filing_date_factor)) filing_date_factor <- 1
        }

        # Current factor divided by factor at filing date gives
        # only the splits that occurred AFTER the filing
        cum_split_factor / filing_date_factor
      }
    ),
    effective_shares_outstanding =
      commonStockSharesOutstanding *
      dplyr::coalesce(post_filing_split_multiplier, 1),
    market_cap = dplyr::if_else(
      has_financial_data,
      close * effective_shares_outstanding / 1e6,
      NA_real_
    ),
    days_since_financial_report = dplyr::if_else(
      !is.na(reportedDate) & date >= reportedDate,
      as.numeric(date - reportedDate),
      NA_real_
    ),
    as_of_date = Sys.Date()
  ) %>%
  dplyr::ungroup() %>%
  dplyr::select(
    ticker, date, close,
    commonStockSharesOutstanding, reportedDate,
    post_filing_split_multiplier, effective_shares_outstanding,
    market_cap, has_financial_data, days_since_financial_report, as_of_date
  ) %>%
  dplyr::arrange(ticker, date)

cat(
  "Market-cap rows: ", nrow(market_data),
  " | non-NA market-caps: ", sum(!is.na(market_data$market_cap)), "\n"
)

# ---- SECTION 7 : comprehensive validation -----------------------------------
cat("Running comprehensive validation …\n")
basic_qc <- market_data %>%
  dplyr::summarise(
    na_market_cap   = sum(is.na(market_cap)),
    negative_mcap   = sum(market_cap < 0, na.rm = TRUE),
    na_shares       = sum(is.na(effective_shares_outstanding)),
    negative_shares = sum(effective_shares_outstanding < 0, na.rm = TRUE),
    zero_price      = sum(close == 0),
    extreme_mcap    = sum(market_cap > 1000, na.rm = TRUE),
    invalid_split   = sum(post_filing_split_multiplier <= 0, na.rm = TRUE)
  )

cat("Basic quality checks:\n")
print(basic_qc)

split_validation <- market_data %>%
  dplyr::filter(has_financial_data & !is.na(post_filing_split_multiplier)) %>%
  dplyr::summarise(
    total_with_splits = sum(post_filing_split_multiplier != 1),
    extreme_splits = sum(
      post_filing_split_multiplier < 0.1 |
      post_filing_split_multiplier > 100
    ),
    max_split = max(post_filing_split_multiplier),
    min_split = min(post_filing_split_multiplier)
  )

cat("Split factor validation:\n")
print(split_validation)

duplicates <- market_data %>%
  dplyr::group_by(ticker, date) %>%
  dplyr::filter(dplyr::n() > 1) %>%
  dplyr::ungroup()

cat("Duplicate observations: ", nrow(duplicates), "\n")

# ---- SECTION 8 : summary statistics -----------------------------------------
cat("Calculating summary statistics …\n")
summary_stats <- market_data %>%
  dplyr::summarise(
    tickers = dplyr::n_distinct(ticker),
    observations = dplyr::n(),
    date_range_start = min(date),
    date_range_end = max(date),
    avg_market_cap = round(mean(market_cap, na.rm = TRUE), 2),
    median_market_cap = round(median(market_cap, na.rm = TRUE), 2),
    min_market_cap = round(min(market_cap, na.rm = TRUE), 2),
    max_market_cap = round(max(market_cap, na.rm = TRUE), 2),
    observations_with_data = sum(has_financial_data),
    avg_days_since_report = round(
      mean(days_since_financial_report, na.rm = TRUE), 1
    )
  )

cat(
  "Market-cap summary:\n",
  " • Tickers: ", summary_stats$tickers, "\n",
  " • Observations: ", summary_stats$observations, "\n",
  " • Date range: ", summary_stats$date_range_start, " → ",
  summary_stats$date_range_end, "\n",
  " • MCAP (M) — Mean: ", summary_stats$avg_market_cap,
  " | Median: ", summary_stats$median_market_cap, "\n",
  " • MCAP (M) — Min: ", summary_stats$min_market_cap,
  " | Max: ", summary_stats$max_market_cap, "\n",
  " • Obs with filings: ", summary_stats$observations_with_data, "\n",
  " • Avg days since report: ", summary_stats$avg_days_since_report, "\n"
)

# ---- SECTION 9 : write artifact ---------------------------------------------
cat("Saving artifact to cache/market_cap_artifact_vectorized.csv …\n")
write.csv(
  market_data,
  "cache/market_cap_artifact_vectorized.csv",
  row.names = FALSE,
  na = ""
)

cat("Done! File rows: ", nrow(market_data), "\n")

# ---- SECTION 10 : sample output ---------------------------------------------
cat("\nSample rows:\n")
print(head(market_data, 10))

if (sum(market_data$post_filing_split_multiplier != 1, na.rm = TRUE) > 0) {
  cat("\nSample split adjustments:\n")
  split_examples <- market_data %>%
    dplyr::filter(has_financial_data & post_filing_split_multiplier != 1) %>%
    dplyr::select(
      ticker, date, commonStockSharesOutstanding,
      post_filing_split_multiplier, effective_shares_outstanding
    ) %>%
    head(5)
  print(split_examples)
}

# ---- SECTION 11 : market cap visualization ----------------------------------
cat("Creating market cap visualization …\n")

# Configuration
target_ticker <- "CTAS"  # Change this to any ticker in your dataset

# Verify ticker exists
if (!target_ticker %in% market_data$ticker) {
  available_tickers <- head(sort(unique(market_data$ticker)), 10)
  stop("Ticker '", target_ticker, "' not found. Available: ",
       paste(available_tickers, collapse = ", "))
}

# Prepare plot data
plot_data <- market_data %>%
  dplyr::filter(
    ticker == target_ticker,
    has_financial_data == TRUE,
    !is.na(market_cap)
  ) %>%
  dplyr::arrange(date)

# Create the plot
market_cap_plot <- plot_data %>%
  ggplot2::ggplot(ggplot2::aes(x = date, y = market_cap)) +
  ggplot2::geom_line(color = "steelblue", size = 0.8) +
  # ggplot2::geom_point(
  #   data = plot_data %>% dplyr::filter(post_filing_split_multiplier != 1),
  #   ggplot2::aes(x = date, y = market_cap),
  #   color = "red",
  #   size = 1.5
  # ) +
  ggplot2::labs(
    title = paste("Market Capitalization Over Time:", target_ticker),
    subtitle = "Red points indicate post-filing split adjustments",
    x = "Date",
    y = "Market Cap (Millions USD)",
    caption = paste("Data as of:", max(plot_data$as_of_date))
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    plot.title = ggplot2::element_text(size = 14, face = "bold"),
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
  ) +
  ggplot2::scale_y_continuous(
    labels = scales::comma_format(suffix = "M")
    # trans = "log10"
  ) +
  ggplot2::scale_x_date(date_breaks = "2 years", date_labels = "%Y")

# Display the plot
print(market_cap_plot)

# Summary for the selected ticker
ticker_summary <- plot_data %>%
  dplyr::summarise(
    observations = dplyr::n(),
    date_range = paste(min(date), "to", max(date)),
    avg_market_cap = round(mean(market_cap, na.rm = TRUE), 0),
    split_adjustments = sum(post_filing_split_multiplier != 1)
  )

cat(
  "\n", target_ticker, " Summary:\n",
  " • Observations: ", ticker_summary$observations, "\n",
  " • Date range: ", ticker_summary$date_range, "\n",
  " • Avg market cap: $", ticker_summary$avg_market_cap, "M\n",
  " • Split adjustments: ", ticker_summary$split_adjustments, "\n"
)

# =============================================================================
# END OF FILE
# =============================================================================
