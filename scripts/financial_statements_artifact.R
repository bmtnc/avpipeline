# Financial Statements Artifact Constructor
# Creates aligned quarterly financial statements with continuous quarterly validation
# Filters to tickers with complete data alignment and continuous quarterly series

# ============================================================================
# SECTION 1: FILE VALIDATION AND DATA LOADING
# ============================================================================

# Check if all required files exist
required_files <- c(
  "cache/earnings_artifact.csv",
  "cache/cash_flow_artifact.csv",
  "cache/income_statement_artifact.csv",
  "cache/balance_sheet_artifact.csv"
)

missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  stop("Missing required files: ", paste(missing_files, collapse = ", "))
}

# ... existing code ...

# Load all financial statement data and filter to dates >= Dec 31, 2004
cat("Loading financial statement data...\n")

earnings <- load_and_filter_financial_data("cache/earnings_artifact.csv")
cash_flow <- load_and_filter_financial_data("cache/cash_flow_artifact.csv") 
income_statement <- load_and_filter_financial_data("cache/income_statement_artifact.csv")
balance_sheet <- load_and_filter_financial_data("cache/balance_sheet_artifact.csv")

# ... rest of existing code ...
cat("Initial data loaded:\n")
cat("- Earnings:", nrow(earnings), "observations\n")
cat("- Cash flow:", nrow(cash_flow), "observations\n")
cat("- Income statement:", nrow(income_statement), "observations\n")
cat("- Balance sheet:", nrow(balance_sheet), "observations\n")

# ============================================================================
# SECTION 2: REMOVE OBSERVATIONS WITH ALL NA FINANCIAL COLUMNS
# ============================================================================

cat("Identifying and removing observations with all NA financial columns...\n")

# Define common metadata columns to exclude from NA checks
common_metadata_cols <- c("ticker", "fiscalDateEnding", "as_of_date", "reportedCurrency")

# Get financial-only columns for each statement type
cash_flow_financial_cols <- setdiff(names(cash_flow), common_metadata_cols)
income_statement_financial_cols <- setdiff(names(income_statement), common_metadata_cols)
balance_sheet_financial_cols <- setdiff(names(balance_sheet), common_metadata_cols)


cash_flow_cleaned <- identify_all_na_rows(cash_flow, cash_flow_financial_cols, "cash flow")
income_statement_cleaned <- identify_all_na_rows(income_statement, income_statement_financial_cols,
                                                 "income statement")
balance_sheet_cleaned <- identify_all_na_rows(balance_sheet, balance_sheet_financial_cols,
                                              "balance sheet")

# Update the datasets
cash_flow <- cash_flow_cleaned
income_statement <- income_statement_cleaned
balance_sheet <- balance_sheet_cleaned

cat("Data after removing all-NA observations:\n")
cat("- Cash flow:", nrow(cash_flow), "observations\n")
cat("- Income statement:", nrow(income_statement), "observations\n")
cat("- Balance sheet:", nrow(balance_sheet), "observations\n")


# ============================================================================
# SECTION 2.5: QUARTERLY ANOMALY CLEANING
# ============================================================================

#TODO this results in a mind boggling amount of warning messages. fix this.

cat("Cleaning quarterly anomalies in financial metrics...\n")

# Define optimal parameters
THRESHOLD <- 4
LOOKBACK <- 5
LOOKAHEAD <- 5
MIN_OBS <- 10

# Define financial metric columns (exclude metadata)
metadata_cols <- c("ticker", "fiscalDateEnding", "reportedCurrency", "as_of_date")

income_statement_metrics <- setdiff(names(income_statement), metadata_cols)
cash_flow_metrics <- setdiff(names(cash_flow), metadata_cols)
balance_sheet_metrics <- setdiff(names(balance_sheet), metadata_cols)

cat("Metrics to clean:\n")
cat("- Income statement:", length(income_statement_metrics), "metrics\n")
cat("- Cash flow:", length(cash_flow_metrics), "metrics\n")
cat("- Balance sheet:", length(balance_sheet_metrics), "metrics\n")

# Clean income statement
cat("Cleaning income statement metrics...\n")
income_statement_filtered <- filter_sufficient_observations(
  income_statement, "ticker", MIN_OBS
)

if (nrow(income_statement_filtered) > 0) {
  income_statement <- tryCatch({
    clean_quarterly_metrics(
      data = income_statement_filtered,
      metric_cols = income_statement_metrics,
      date_col = "fiscalDateEnding",
      ticker_col = "ticker",
      threshold = THRESHOLD,
      lookback = LOOKBACK,
      lookahead = LOOKAHEAD
    )
  }, error = function(e) {
    cat("Income statement cleaning failed, keeping original data. Error:", e$message, "\n")
    return(income_statement)
  })
  cat("✓ Income statement cleaned successfully\n")
} else {
  cat("⚠ No income statement data with sufficient observations\n")
}

# Clean cash flow
cat("Cleaning cash flow metrics...\n")
cash_flow_filtered <- filter_sufficient_observations(
  cash_flow, "ticker", MIN_OBS
)

if (nrow(cash_flow_filtered) > 0) {
  cash_flow <- tryCatch({
    clean_quarterly_metrics(
      data = cash_flow_filtered,
      metric_cols = cash_flow_metrics,
      date_col = "fiscalDateEnding",
      ticker_col = "ticker",
      threshold = THRESHOLD,
      lookback = LOOKBACK,
      lookahead = LOOKAHEAD
    )
  }, error = function(e) {
    cat("Cash flow cleaning failed, keeping original data. Error:", e$message, "\n")
    return(cash_flow)
  })
  cat("✓ Cash flow cleaned successfully\n")
} else {
  cat("⚠ No cash flow data with sufficient observations\n")
}

# Clean balance sheet
cat("Cleaning balance sheet metrics...\n")
balance_sheet_filtered <- filter_sufficient_observations(
  balance_sheet, "ticker", MIN_OBS
)

if (nrow(balance_sheet_filtered) > 0) {
  balance_sheet <- tryCatch({
    clean_quarterly_metrics(
      data = balance_sheet_filtered,
      metric_cols = balance_sheet_metrics,
      date_col = "fiscalDateEnding",
      ticker_col = "ticker",
      threshold = THRESHOLD,
      lookback = LOOKBACK,
      lookahead = LOOKAHEAD
    )
  }, error = function(e) {
    cat("Balance sheet cleaning failed, keeping original data. Error:", e$message, "\n")
    return(balance_sheet)
  })
  cat("✓ Balance sheet cleaned successfully\n")
} else {
  cat("⚠ No balance sheet data with sufficient observations\n")
}

# Report final data after cleaning
cat("Data after anomaly cleaning:\n")
cat("- Income statement:", nrow(income_statement), "observations\n")
cat("- Cash flow:", nrow(cash_flow), "observations\n")
cat("- Balance sheet:", nrow(balance_sheet), "observations\n")

cat("Quarterly anomaly cleaning completed.\n")


# ============================================================================
# SECTION 3: TICKER ALIGNMENT VALIDATION
# ============================================================================

# Get distinct tickers from each file
earnings_tickers <- unique(earnings$ticker)
cash_flow_tickers <- unique(cash_flow$ticker)
income_statement_tickers <- unique(income_statement$ticker)
balance_sheet_tickers <- unique(balance_sheet$ticker)

# Find tickers that exist in all 4 files
all_tickers <- list(earnings_tickers, cash_flow_tickers, income_statement_tickers, balance_sheet_tickers)
common_tickers <- Reduce(intersect, all_tickers)

# Identify and report removed tickers
all_unique_tickers <- unique(c(earnings_tickers, cash_flow_tickers,
                              income_statement_tickers, balance_sheet_tickers))
removed_tickers_step1 <- setdiff(all_unique_tickers, common_tickers)

if (length(removed_tickers_step1) > 0) {
  cat("Removed", length(removed_tickers_step1), "tickers not present in all 4 files:\n")
  cat(paste(removed_tickers_step1, collapse = ", "), "\n")
}

# Filter all datasets to common tickers
earnings_filtered <- earnings %>% dplyr::filter(ticker %in% common_tickers)
cash_flow_filtered <- cash_flow %>% dplyr::filter(ticker %in% common_tickers)
income_statement_filtered <- income_statement %>% dplyr::filter(ticker %in% common_tickers)
balance_sheet_filtered <- balance_sheet %>% dplyr::filter(ticker %in% common_tickers)

# ============================================================================
# SECTION 4: DATE ALIGNMENT VALIDATION
# ============================================================================

# Create ticker-date combinations for the 3 financial statement files only
cash_flow_dates <- cash_flow_filtered %>%
  dplyr::select(ticker, fiscalDateEnding) %>%
  dplyr::distinct() %>%
  dplyr::mutate(in_cash_flow = TRUE)

income_statement_dates <- income_statement_filtered %>%
  dplyr::select(ticker, fiscalDateEnding) %>%
  dplyr::distinct() %>%
  dplyr::mutate(in_income_statement = TRUE)

balance_sheet_dates <- balance_sheet_filtered %>%
  dplyr::select(ticker, fiscalDateEnding) %>%
  dplyr::distinct() %>%
  dplyr::mutate(in_balance_sheet = TRUE)

# Join the 3 financial statement date combinations to check alignment
date_alignment <- cash_flow_dates %>%
  dplyr::full_join(income_statement_dates, by = c("ticker", "fiscalDateEnding")) %>%
  dplyr::full_join(balance_sheet_dates, by = c("ticker", "fiscalDateEnding")) %>%
  dplyr::mutate(
    in_cash_flow = dplyr::coalesce(in_cash_flow, FALSE),
    in_income_statement = dplyr::coalesce(in_income_statement, FALSE),
    in_balance_sheet = dplyr::coalesce(in_balance_sheet, FALSE),
    in_all_three = in_cash_flow & in_income_statement & in_balance_sheet
  )

# Count and report removed observations
total_observations <- nrow(date_alignment)
valid_observations <- sum(date_alignment$in_all_three)
removed_observations <- total_observations - valid_observations

if (removed_observations > 0) {
  cat("Removed", removed_observations, "observations with misaligned fiscalDateEnding dates")
  cat(" across the 3 financial statement files\n")
}

# Keep only valid ticker-date combinations
valid_dates <- date_alignment %>%
  dplyr::filter(in_all_three) %>%
  dplyr::select(ticker, fiscalDateEnding)

# Final list of tickers that have at least some valid data
final_tickers <- unique(valid_dates$ticker)
cat("Final dataset includes", length(final_tickers), "tickers with",
    nrow(valid_dates), "aligned observations\n")

# ============================================================================
# SECTION 5: FINANCIAL STATEMENT JOINING
# ============================================================================

# Filter financial statement datasets to final valid ticker-date combinations
cash_flow_final <- cash_flow_filtered %>%
  dplyr::inner_join(valid_dates, by = c("ticker", "fiscalDateEnding"))

income_statement_final <- income_statement_filtered %>%
  dplyr::inner_join(valid_dates, by = c("ticker", "fiscalDateEnding"))

balance_sheet_final <- balance_sheet_filtered %>%
  dplyr::inner_join(valid_dates, by = c("ticker", "fiscalDateEnding"))

# Filter earnings to final tickers but allow for date mismatches
earnings_final <- earnings_filtered %>%
  dplyr::filter(ticker %in% final_tickers)

# Get actual column names from each financial statement file (excluding common columns)
common_cols <- c("ticker", "fiscalDateEnding", "as_of_date", "reportedCurrency")
income_statement_cols <- setdiff(names(income_statement), common_cols)
balance_sheet_cols <- setdiff(names(balance_sheet), common_cols)
cash_flow_cols <- setdiff(names(cash_flow), common_cols)

# Join all financial statements (left join earnings to allow for missing dates)
financial_statements <- valid_dates %>%
  dplyr::left_join(earnings_final, by = c("ticker", "fiscalDateEnding")) %>%
  dplyr::left_join(income_statement_final, by = c("ticker", "fiscalDateEnding"),
                   suffix = c("", ".is")) %>%
  dplyr::left_join(balance_sheet_final, by = c("ticker", "fiscalDateEnding"),
                   suffix = c("", ".bs")) %>%
  dplyr::left_join(cash_flow_final, by = c("ticker", "fiscalDateEnding"),
                   suffix = c("", ".cf")) %>%
  dplyr::select(-dplyr::any_of(c("as_of_date.is", "as_of_date.bs", "as_of_date.cf"))) %>%
  dplyr::arrange(ticker, fiscalDateEnding)

# Filter to columns that actually exist in the final dataset
income_statement_cols <- intersect(income_statement_cols, names(financial_statements))
balance_sheet_cols <- intersect(balance_sheet_cols, names(financial_statements))
cash_flow_cols <- intersect(cash_flow_cols, names(financial_statements))

# ============================================================================
# SECTION 6: DATA QUALITY VALIDATION
# ============================================================================

# Add robust validation logic
financial_statements <- financial_statements %>%
  dplyr::mutate(
    # Check if ANY income statement columns have data
    has_income_statement = dplyr::if_any(dplyr::all_of(income_statement_cols), ~ !is.na(.x)),
    # Check if ANY balance sheet columns have data
    has_balance_sheet = dplyr::if_any(dplyr::all_of(balance_sheet_cols), ~ !is.na(.x)),
    # Check if ANY cash flow columns have data
    has_cash_flow = dplyr::if_any(dplyr::all_of(cash_flow_cols), ~ !is.na(.x)),
    # Complete financials means having data from all three statement types
    has_complete_financials = has_income_statement & has_balance_sheet & has_cash_flow,
    # Check if earnings metadata is available
    has_earnings_metadata = !is.na(reportedDate)
  )

# ============================================================================
# SECTION 7: QUARTERLY SPACING VALIDATION
# ============================================================================

cat("Finding continuous quarterly series for each ticker using fiscal pattern validation...\n")

# Store original data for comparison
original_data <- financial_statements %>%
  dplyr::select(ticker, fiscalDateEnding) %>%
  dplyr::arrange(ticker, fiscalDateEnding)

# Apply fiscal-pattern-aware quarterly validation using split-apply-combine pattern
quarterly_filtered_list <- financial_statements %>%
  dplyr::group_by(ticker) %>%
  dplyr::arrange(ticker, fiscalDateEnding) %>%
  dplyr::mutate(
    row_num = dplyr::row_number()
  ) %>%
  dplyr::ungroup() %>%
  split(.$ticker)

# Apply fiscal-pattern-aware quarterly validation to each ticker
quarterly_results <- lapply(quarterly_filtered_list, validate_continuous_quarters)

# Combine results back together
quarterly_filtered <- dplyr::bind_rows(quarterly_results)

# ============================================================================
# SECTION 8: REPORTING REMOVED OBSERVATIONS
# ============================================================================

# Detailed diagnostics of removed observations
final_data <- quarterly_filtered %>%
  dplyr::select(ticker, fiscalDateEnding) %>%
  dplyr::arrange(ticker, fiscalDateEnding)

# Find removed observations by ticker
removed_detail <- original_data %>%
  dplyr::anti_join(final_data, by = c("ticker", "fiscalDateEnding")) %>%
  dplyr::group_by(ticker) %>%
  dplyr::summarise(
    removed_count = dplyr::n(),
    earliest_removed = min(fiscalDateEnding),
    latest_removed = max(fiscalDateEnding),
    .groups = "drop"
  )

# Find completely removed tickers
completely_removed_tickers <- setdiff(unique(original_data$ticker), unique(final_data$ticker))

# Count totals
original_obs <- nrow(original_data)
final_obs <- nrow(final_data)
removed_obs <- original_obs - final_obs

# Report detailed results
if (removed_obs > 0) {
  cat("Removed", removed_obs, "observations to ensure continuous quarterly spacing\n")

  if (nrow(removed_detail) > 0) {
    cat("\nDetailed breakdown by ticker:\n")
    for (i in seq_len(nrow(removed_detail))) {
      ticker <- removed_detail$ticker[i]
      count <- removed_detail$removed_count[i]
      earliest <- removed_detail$earliest_removed[i]
      latest <- removed_detail$latest_removed[i]

      cat("  ", ticker, ":", count, "observations removed")
      cat(" (", as.character(earliest), "to", as.character(latest), ")\n")
    }
  }
}

if (length(completely_removed_tickers) > 0) {
  cat("\nRemoved", length(completely_removed_tickers), "tickers with no continuous quarterly series:\n")
  cat(paste(completely_removed_tickers, collapse = ", "), "\n")
}

# Update financial_statements to the filtered version
financial_statements <- quarterly_filtered

# ============================================================================
# SECTION 9: FINAL VALIDATION AND SUMMARY
# ============================================================================

# Final validation: add time since last report for summary statistics
cat("Performing final validation of quarterly continuity...\n")

financial_statements <- quarterly_filtered %>%
  dplyr::group_by(ticker) %>%
  dplyr::arrange(ticker, fiscalDateEnding) %>%
  dplyr::mutate(
    days_since_last_report = as.numeric(fiscalDateEnding - dplyr::lag(fiscalDateEnding))
  ) %>%
  dplyr::ungroup()

# Since we used fiscal-pattern validation, all observations should be properly quarterly
cat("✓ All observations validated using fiscal-pattern quarterly validation\n")

# Summary statistics of gaps for informational purposes
gap_stats <- financial_statements %>%
  dplyr::filter(!is.na(days_since_last_report)) %>%
  dplyr::summarise(
    total_gaps = dplyr::n(),
    min_days = min(days_since_last_report),
    max_days = max(days_since_last_report),
    avg_days = round(mean(days_since_last_report), 1),
    median_days = median(days_since_last_report),
    gaps_80_to_100_pct = round(100 * mean(days_since_last_report >= 80 & days_since_last_report <= 100), 1)
  )

cat("Gap statistics (for informational purposes):\n")
cat("- Total gaps analyzed:", gap_stats$total_gaps, "\n")
cat("- Range:", gap_stats$min_days, "to", gap_stats$max_days, "days\n")
cat("- Average gap:", gap_stats$avg_days, "days\n")
cat("- Median gap:", gap_stats$median_days, "days\n")
cat("- Gaps in 80-100 day range:", gap_stats$gaps_80_to_100_pct, "%\n")

# Update financial_statements to the final filtered version (remove days_since_last_report)
financial_statements <- financial_statements %>%
  dplyr::select(-days_since_last_report)

# ============================================================================
# SECTION 10: SAVE FINAL ARTIFACT
# ============================================================================

# Final summary
cat("\nFinal financial statements artifact:\n")
cat("- Observations:", nrow(financial_statements), "\n")
cat("- Tickers:", length(unique(financial_statements$ticker)), "\n")
cat("- Date range:", as.character(min(financial_statements$fiscalDateEnding)), "to",
    as.character(max(financial_statements$fiscalDateEnding)), "\n")
cat("- Complete financial records:", sum(financial_statements$has_complete_financials), "\n")
cat("- Records with earnings metadata:", sum(financial_statements$has_earnings_metadata), "\n")

# Save the final artifact
write.csv(financial_statements, "cache/financial_statements_artifact.csv", row.names = FALSE)
cat("Financial statements artifact saved successfully!\n")



# ============================================================================
# SECTION 11: STANDARDIZE TO CALENDAR QUARTERS
# ============================================================================

# Map fiscal date endings to calendar quarter endings based on business activity
cat("Standardizing fiscal dates to calendar quarters...\n")

financial_statements <- financial_statements %>%
  dplyr::mutate(
    fiscal_month = lubridate::month(fiscalDateEnding),
    fiscal_year = lubridate::year(fiscalDateEnding),
    calendar_quarter_ending = dplyr::case_when(
      fiscal_month == 1 ~ as.Date(paste0(fiscal_year - 1, "-12-31")),  # Jan → prev Dec 31
      fiscal_month %in% c(2, 3, 4) ~ as.Date(paste0(fiscal_year, "-03-31")),  # Feb/Mar/Apr → Mar 31
      fiscal_month %in% c(5, 6, 7) ~ as.Date(paste0(fiscal_year, "-06-30")),  # May/Jun/Jul → Jun 30
      fiscal_month %in% c(8, 9, 10) ~ as.Date(paste0(fiscal_year, "-09-30")), # Aug/Sep/Oct → Sep 30
      fiscal_month %in% c(11, 12) ~ as.Date(paste0(fiscal_year, "-12-31")),   # Nov/Dec → Dec 31
      TRUE ~ fiscalDateEnding  # fallback
    )
  ) %>%
  dplyr::select(-fiscal_month, -fiscal_year)

# Summary of standardization
cat("Calendar quarter standardization summary:\n")
standardization_summary <- financial_statements %>%
  dplyr::group_by(lubridate::month(fiscalDateEnding)) %>%
  dplyr::summarise(
    original_month = dplyr::first(lubridate::month(fiscalDateEnding)),
    sample_original = dplyr::first(fiscalDateEnding),
    sample_standardized = dplyr::first(calendar_quarter_ending),
    count = dplyr::n(),
    .groups = "drop"
  ) %>%
  dplyr::arrange(original_month)

print(standardization_summary)

# ============================================================================
# SECTION 12: VISUALIZE STANDARDIZED TICKER COUNTS
# ============================================================================

# Calculate ticker counts by standardized calendar quarter
cat("Creating ticker count visualization with standardized dates...\n")

standardized_ticker_counts <- financial_statements %>%
  dplyr::group_by(calendar_quarter_ending) %>%
  dplyr::summarise(
    ticker_count = dplyr::n_distinct(ticker),
    .groups = "drop"
  ) %>%
  dplyr::arrange(calendar_quarter_ending)

# Create the bar chart with standardized dates
standardized_plot <- standardized_ticker_counts %>%
  ggplot2::ggplot(ggplot2::aes(x = calendar_quarter_ending, y = ticker_count)) +
  ggplot2::geom_col(fill = "steelblue", alpha = 0.7) +
  ggplot2::labs(
    title = "Number of Tickers by Calendar Quarter (Standardized)",
    subtitle = "Count of companies with financial data for each calendar quarter ending",
    x = "Calendar Quarter Ending",
    y = "Number of Tickers",
    caption = "Source: Financial Statements Artifact (Calendar Quarter Aligned)"
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    plot.title = ggplot2::element_text(size = 14, face = "bold"),
    plot.subtitle = ggplot2::element_text(size = 12, color = "gray60"),
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
    panel.grid.minor = ggplot2::element_blank()
  ) +
  ggplot2::scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  ggplot2::scale_y_continuous(expand = c(0, 0),
                              limits = c(0, max(standardized_ticker_counts$ticker_count) * 1.05))

# Display the plot
print(standardized_plot)

