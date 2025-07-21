# =============================================================================
# Unified Financial Artifact Explorer
# =============================================================================
#
# Simple exploration script to load and visualize the unified financial artifact
# Demonstrates plotting capabilities with anomaly detection for any ticker/metric
#
# =============================================================================

# ---- CONFIGURATION PARAMETERS -----------------------------------------------
TICKER <- "EQIX"                # Ticker symbol to analyze
METRIC <- "operating_cash_flow_per_share"     # Metric column name to plot
ANOMALY_THRESHOLD <- 2           # MAD threshold for anomaly detection
PLOT_TITLE <- NULL               # Custom plot title (NULL for auto-generated)

# ---- SECTION 1: Load required functions -------------------------------------
source("R/read_cached_data.R")
source("R/create_bar_plot.R")
source("R/detect_time_series_anomalies.R")

# ---- SECTION 2: Load unified financial artifact -----------------------------
cat("Loading unified financial artifact ...\n")

unified_final <- read_cached_data(
  "cache/unified_financial_artifact.csv",
  date_columns = c("date", "fiscalDateEnding", "reportedDate", "as_of_date", "calendar_quarter_ending")
)

cat("Loaded dataset: ", nrow(unified_final), " rows, ", ncol(unified_final), " columns\n")

# ---- SECTION 3: Validate parameters -----------------------------------------
# Check if ticker exists
if (!TICKER %in% unified_final$ticker) {
  available_tickers <- unique(unified_final$ticker)
  stop("Ticker '", TICKER, "' not found. Available tickers: ", paste(head(available_tickers, 10), collapse = ", "), "...")
}

# Check if metric column exists
if (!METRIC %in% names(unified_final)) {
  available_metrics <- names(unified_final)[grepl("_per_share$|^price_to_|^market_cap|^enterprise_value", names(unified_final))]
  stop("Metric '", METRIC, "' not found. Common metrics: ", paste(head(available_metrics, 10), collapse = ", "), "...")
}

# ---- SECTION 4: Create visualization with anomaly detection -----------------
cat("Creating ", METRIC, " plot for ", TICKER, " with anomaly detection ...\n")

df <- unified_final %>%
  dplyr::filter(
    ticker == TICKER,
    has_complete_financial_data,
    !is.na(!!rlang::sym(METRIC))
  ) %>%
  dplyr::arrange(date) %>%
  dplyr::mutate(
    # Calculate percentage change
    metric_pct_change = (!!rlang::sym(METRIC) - dplyr::lag(!!rlang::sym(METRIC))) / dplyr::lag(!!rlang::sym(METRIC)) * 100
  ) %>%
  dplyr::mutate(metric_pct_change = dplyr::coalesce(metric_pct_change, 0))  # Fill first NA with 0

if (nrow(df) == 0) {
  stop("No data available for ticker '", TICKER, "' with complete financial data.")
}

# Run anomaly detection on NON-ZERO percentage changes only
non_zero_changes <- df %>%
  dplyr::filter(metric_pct_change != 0)

if (nrow(non_zero_changes) >= 10) {
  anomalies <- detect_time_series_anomalies(non_zero_changes$metric_pct_change, threshold = ANOMALY_THRESHOLD)

  # Get anomaly dates
  anomaly_dates <- non_zero_changes %>%
    dplyr::mutate(is_anomaly = anomalies) %>%
    dplyr::filter(is_anomaly) %>%
    dplyr::pull(date)

  # Flag anomalies in original data
  df$is_anomaly <- df$date %in% anomaly_dates

  cat("Detected ", sum(anomalies), " anomalies out of ", nrow(non_zero_changes), " non-zero changes\n")
} else {
  df$is_anomaly <- FALSE
  cat("Not enough non-zero changes for anomaly detection (need >= 10)\n")
}

# Create base plot
base_plot <- create_bar_plot(
  df,
  date_col = "date",
  ticker_col = "ticker",
  value_col = METRIC,
  title = PLOT_TITLE
) %>% print()

# # Add anomaly overlay
# final_plot <- base_plot +
#   ggplot2::geom_point(
#     data = df %>% dplyr::filter(is_anomaly),
#     ggplot2::aes(x = date, y = !!rlang::sym(METRIC)),
#     color = "red",
#     size = 3,
#     alpha = 0.8
#   ) +
#   ggplot2::labs(
#     subtitle = paste0("Red points indicate anomalous % changes (MAD threshold = ",
#                      ANOMALY_THRESHOLD, "). ", sum(df$is_anomaly), " anomalies detected.")
#   )

# print(final_plot)

# ---- SECTION 5: Summary statistics ------------------------------------------
cat("\nSummary statistics for ", TICKER, " - ", METRIC, ":\n")
print(summary(df[[METRIC]]))

if (sum(df$is_anomaly) > 0) {
  cat("\nAnomalous observations:\n")
  anomaly_summary <- df %>%
    dplyr::filter(is_anomaly) %>%
    dplyr::select(date, !!rlang::sym(METRIC), metric_pct_change) %>%
    dplyr::arrange(date)
  print(anomaly_summary)
}

cat("Plot created successfully!\n")
