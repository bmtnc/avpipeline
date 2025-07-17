# =============================================================================
# Quarterly Data Cleaning with Temporary Anomaly Detection
# =============================================================================
#
# CLEANING METHOD RATIONALE:
# Alpha Vantage financial data contains significant quality issues, particularly
# temporary spikes and drops in key financial metrics like shares outstanding,
# earnings, and revenue. These anomalies appear as multi-quarter sequences where
# values temporarily deviate from normal levels before reverting - for example,
# share counts that inexplicably drop 70% for several quarters then return to
# baseline levels. Such data corruption renders financial analysis unreliable and
# creates misleading per-share calculations and valuation ratios.
#
# Traditional percentage-change anomaly detection fails because it only flags the
# initial extreme change, leaving subsequent anomalous quarters uncleaned. This
# creates interpolation problems where linear interpolation bridges from normal
# data to persistent anomalies, resulting in unrealistic flat plateaus. Our solution
# uses a lookback/lookahead baseline approach: for each quarter, we establish a
# "normal" baseline using surrounding quarters (typically 4 before and 4 after),
# excluding immediate neighbors to prevent contamination. Any quarter deviating
# significantly from this baseline (using MAD threshold) is flagged as anomalous,
# capturing entire sequences of temporary anomalies. After flagging, we replace
# anomalous values with NA and interpolate smoothly between normal values, producing
# clean, analytically reliable quarterly data suitable for financial modeling.
#
# =============================================================================

# Detect temporary anomalies using lookback/lookahead baseline
detect_temporary_anomalies <- function(values, lookback = 4, lookahead = 4, threshold = 3) {
  n <- length(values)
  anomaly_flags <- rep(FALSE, n)

  # Calculate centered moving average for each point
  for(i in 1:n) {
    # Define window around current point
    window_start <- max(1, i - lookback)
    window_end <- min(n, i + lookahead)

    # Exclude current point and surrounding points to avoid contamination
    baseline_indices <- c(window_start:(i-2), (i+2):window_end)
    baseline_indices <- baseline_indices[baseline_indices > 0 & baseline_indices <= n]

    if(length(baseline_indices) >= 6) {  # Need minimum baseline points
      baseline_values <- values[baseline_indices]
      baseline_median <- median(baseline_values, na.rm = TRUE)
      baseline_mad <- mad(baseline_values, na.rm = TRUE)

      # Flag if current value is extreme relative to baseline
      if(baseline_mad > 0) {
        anomaly_flags[i] <- abs(values[i] - baseline_median) > threshold * baseline_mad
      }
    }
  }

  anomaly_flags
}

# Helper function to filter groups with sufficient observations
filter_sufficient_observations <- function(data, group_col, min_obs) {
  group_sym <- rlang::sym(group_col)

  data %>%
    dplyr::group_by(!!group_sym) %>%
    dplyr::add_count() %>%
    dplyr::ungroup() %>%
    dplyr::filter(n >= min_obs) %>%
    dplyr::select(-n)
}

# Add anomaly flag columns using temporary anomaly detection
add_anomaly_flag_columns <- function(data, metric_cols, threshold = 3, lookback = 4, lookahead = 4) {
  data %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(metric_cols),
        ~ detect_temporary_anomalies(., lookback, lookahead, threshold),
        .names = "{.col}_anomaly"
      )
    )
}

# Clean original columns by replacing anomalies with NA and interpolating
clean_original_columns <- function(data, metric_cols) {
  result <- data
  for(metric in metric_cols) {
    anomaly_col <- paste0(metric, "_anomaly")
    if(anomaly_col %in% names(result)) {
      result <- result %>%
        dplyr::mutate(
          !!rlang::sym(metric) := zoo::na.approx(
            ifelse(!!rlang::sym(anomaly_col), NA, !!rlang::sym(metric)),
            na.rm = FALSE
          )
        )
    }
  }
  result
}

# Main function - clean quarterly metrics with temporary anomaly detection
clean_quarterly_metrics <- function(data, metric_cols, date_col, ticker_col,
                                    threshold = 3, lookback = 4, lookahead = 4,
                                    min_obs = 10) {

  date_sym <- rlang::sym(date_col)
  ticker_sym <- rlang::sym(ticker_col)

  data %>%
    dplyr::select(!!ticker_sym, !!date_sym, dplyr::all_of(metric_cols)) %>%
    dplyr::distinct() %>%
    dplyr::arrange(!!ticker_sym, !!date_sym) %>%
    filter_sufficient_observations(ticker_col, min_obs) %>%
    dplyr::group_by(!!ticker_sym) %>%
    add_anomaly_flag_columns(metric_cols, threshold, lookback, lookahead) %>%
    clean_original_columns(metric_cols) %>%
    dplyr::ungroup()
}

# =============================================================================
# Test Quarterly Cleaning on Specified Ticker and Metric
# =============================================================================

# ---- CONFIGURATION PARAMETERS -----------------------------------------------
TICKER <- "TSLA"                    # Ticker symbol to analyze
METRIC <- "netIncome"         # Metric column name to clean and plot
ANOMALY_THRESHOLD <- 3               # MAD threshold for anomaly detection
LOOKBACK <- 5                        # Quarters to look back for baseline
LOOKAHEAD <- 5                       # Quarters to look ahead for baseline
MIN_OBSERVATIONS <- 10               # Minimum observations required for cleaning
PLOT_TITLE <- NULL                   # Custom plot title (NULL for auto-generated)

# ---- SECTION 2: Load unified financial artifact -----------------------------
cat("Loading unified financial artifact ...\n")

# unified_final <- read_cached_data(
#   "cache/unified_financial_artifact.csv",
#   date_columns = c("date", "fiscalDateEnding", "reportedDate", "financial_reportedDate", "as_of_date")
# )

cat("Loaded dataset: ", nrow(unified_final), " rows, ", ncol(unified_final), " columns\n")

# ---- SECTION 3: Validate parameters -----------------------------------------
# Check if ticker exists
if (!TICKER %in% unified_final$ticker) {
  available_tickers <- unique(unified_final$ticker)
  stop("Ticker '", TICKER, "' not found. Available tickers: ", paste(head(available_tickers, 10), collapse = ", "), "...")
}

# Check if metric column exists
if (!METRIC %in% names(unified_final)) {
  available_metrics <- names(unified_final)[grepl("_per_share$|^price_to_|^market_cap|^enterprise_value|^commonStock", names(unified_final))]
  stop("Metric '", METRIC, "' not found. Common metrics: ", paste(head(available_metrics, 10), collapse = ", "), "...")
}

# ---- SECTION 4: Apply quarterly cleaning ------------------------------------
cat("Applying quarterly cleaning to ", METRIC, " ...\n")

# Clean the quarterly data
cleaned_quarterly <- clean_quarterly_metrics(
  data = unified_final,
  metric_cols = c(METRIC),
  date_col = "reportedDate",
  ticker_col = "ticker",
  threshold = ANOMALY_THRESHOLD,
  lookback = LOOKBACK,
  lookahead = LOOKAHEAD,
  min_obs = MIN_OBSERVATIONS
)

cat("Cleaned quarterly data: ", nrow(cleaned_quarterly), " rows\n")

# Join cleaned data back to unified dataset
unified_cleaned <- unified_final %>%
  dplyr::select(-!!rlang::sym(METRIC)) %>%
  dplyr::left_join(
    cleaned_quarterly %>% dplyr::select(ticker, reportedDate, !!rlang::sym(METRIC)),
    by = c("ticker", "reportedDate")
  ) %>%
  # Forward fill cleaned quarterly data to daily frequency
  dplyr::group_by(ticker) %>%
  dplyr::arrange(date) %>%
  tidyr::fill(!!rlang::sym(METRIC), .direction = "down") %>%
  dplyr::ungroup()

# ---- SECTION 5: Compare quarterly before and after (NOT daily) --------------
cat("Creating quarterly before/after comparison for ", TICKER, " ", METRIC, " ...\n")

# Original QUARTERLY data (extract from unified_final)
df_quarterly_original <- unified_final %>%
  dplyr::select(ticker, reportedDate, !!rlang::sym(METRIC)) %>%
  dplyr::distinct() %>%
  dplyr::filter(
    ticker == TICKER,
    !is.na(!!rlang::sym(METRIC))
  ) %>%
  dplyr::arrange(reportedDate) %>%
  dplyr::mutate(data_type = "Original")

# Cleaned QUARTERLY data (from our cleaning function)
df_quarterly_cleaned <- cleaned_quarterly %>%
  dplyr::filter(
    ticker == TICKER,
    !is.na(!!rlang::sym(METRIC))
  ) %>%
  dplyr::arrange(reportedDate) %>%
  dplyr::select(ticker, reportedDate, !!rlang::sym(METRIC)) %>%
  dplyr::mutate(data_type = "Cleaned")

# Combine quarterly data for comparison
df_quarterly_combined <- dplyr::bind_rows(df_quarterly_original, df_quarterly_cleaned)

# Create quarterly comparison plot
quarterly_comparison_plot <- df_quarterly_combined %>%
  ggplot2::ggplot(ggplot2::aes(x = reportedDate, y = !!rlang::sym(METRIC), fill = data_type)) +
  ggplot2::geom_col(position = "dodge", alpha = 0.7) +
  ggplot2::facet_wrap(~data_type, ncol = 1) +
  ggplot2::labs(
    title = if(is.null(PLOT_TITLE)) {
      paste0(TICKER, " ", stringr::str_to_title(gsub("_", " ", METRIC)),
             ": Quarterly Before vs After Cleaning")
    } else {
      PLOT_TITLE
    },
    x = "Report Date (Quarterly)",
    y = stringr::str_to_title(gsub("_", " ", METRIC)),
    fill = "Data Type"
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    plot.title = ggplot2::element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
  )

print(quarterly_comparison_plot)

# ---- SECTION 6: Quarterly summary statistics --------------------------------
cat("\nQuarterly summary statistics comparison:\n")
cat("Original quarterly ", TICKER, " ", METRIC, ":\n")
print(summary(df_quarterly_original[[METRIC]]))

cat("\nCleaned quarterly ", TICKER, " ", METRIC, ":\n")
print(summary(df_quarterly_cleaned[[METRIC]]))

# Show quarterly anomalies in detail
if (nrow(cleaned_quarterly) > 0) {
  ticker_anomalies <- cleaned_quarterly %>%
    dplyr::filter(
      ticker == TICKER,
      !!rlang::sym(paste0(METRIC, "_anomaly")) == TRUE
    ) %>%
    dplyr::select(
      ticker,
      reportedDate,
      value = !!rlang::sym(METRIC)
    )

  if (nrow(ticker_anomalies) > 0) {
    cat("\n", TICKER, " quarterly anomalies detected and cleaned:\n")
    print(ticker_anomalies)
  } else {
    cat("\nNo quarterly anomalies detected for ", TICKER, " ", METRIC, "\n")
  }
}

# Show quarterly data side-by-side
cat("\nQuarterly data side-by-side:\n")
quarterly_comparison_table <- df_quarterly_original %>%
  dplyr::select(reportedDate, original = !!rlang::sym(METRIC)) %>%
  dplyr::left_join(
    df_quarterly_cleaned %>% dplyr::select(reportedDate, cleaned = !!rlang::sym(METRIC)),
    by = "reportedDate"
  ) %>%
  dplyr::mutate(
    difference = cleaned - original,
    pct_change_original = (original - dplyr::lag(original)) / abs(dplyr::lag(original)) * 100
  )

print(quarterly_comparison_table)

cat("\nQuarterly cleaning test completed!\n")
