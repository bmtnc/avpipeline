# =============================================================================
# TTM Per-Share Financial Artifact Description
# =============================================================================
#
# ttm_per_share_financial_artifact.csv
#
# Daily frequency dataset that bridges quarterly financial reporting with daily
# market data by mapping financial metrics to actual earnings announcement dates.
#
# CORE DESIGN:
# - Frequency: Daily observations (long-form)
# - Index: `ticker` and `date`
# - Key Innovation: Quarterly financial statements mapped to `date` based on
#   actual earnings announcement dates (`reportedDate`), then forward-filled
#   to create daily frequency
#
# DATE COLUMN USAGE:
# - `date` - Primary column for daily frequency analysis, synchronized with daily prices
# - `fiscalDateEnding` - Use for quarterly frequency analysis of financial KPIs only
#
# CONTENTS:
# - Market data: Daily prices, volume, dividends, splits
# - Share metrics: `commonStockSharesOutstanding`, `effective_shares_outstanding`, `market_cap`
# - Financial metrics (per-share basis):
#   * Flow metrics: Income statement & cash flow items converted to TTM per-share
#     (e.g., `fcf_ttm_per_share`, `ebitda_ttm_per_share`)
#   * Balance sheet metrics: Point-in-time per-share values
#     (e.g., `totalAssets_per_share`, `tangible_book_value_per_share`)
#
# KEY FEATURES:
# - Quarterly financial data forward-filled until next earnings announcement
# - Ready for daily time-series analysis of fundamental metrics
# - Enables creation of daily frequency fundamental ratios and screens
# - Maintains quarterly granularity via `fiscalDateEnding` for period-specific analysis
#
# PRIMARY USE CASE:
# Daily frequency fundamental analysis, bridging the gap between quarterly
# earnings cycles and daily market movements.
#
# =============================================================================

# =============================================================================
# TTM Per-Share Financial Artifact Explorer - COMPLETE
# =============================================================================

# ---- CONFIGURATION PARAMETERS -----------------------------------------------
TICKER <- "AMZN"
METRIC <- "commonStockSharesOutstanding"
METRIC <- "market_cap"
METRIC <- "fcf_ttm_per_share"
# METRIC <- "ebit_ttm_per_share"
# METRIC <- "ebitda_ttm_per_share"
# METRIC <- "grossProfit_ttm_per_share"
# METRIC <- "tangible_book_value_per_share"
ANOMALY_THRESHOLD <- 2
PLOT_TITLE <- NULL

# ---- SECTION 1: Load required functions -------------------------------------
devtools::load_all()
set_ggplot_theme()

# ---- SECTION 2: Load TTM per-share financial artifact -----------------------
cat("Loading TTM per-share financial artifact ...\n")

date_cols <- c(
  "date",
  "initial_date",
  "latest_date",
  "fiscalDateEnding",
  "reportedDate"
)

# ttm_per_share_data <- read_cached_data(
#   "cache/ttm_per_share_financial_artifact.csv",
#   date_columns = date_cols
# )

# Alternative: Subtract goodwill and other intangibles separately
# Correct calculation for Tangible Book Value per Share
ttm_per_share_data <- ttm_per_share_data %>%
  dplyr::mutate(
    tangible_book_value_per_share = totalShareholderEquity_per_share -
      dplyr::coalesce(goodwill_per_share, 0)
      # dplyr::coalesce(intangibleAssets_per_share, 0)
  )

cat("Loaded dataset: ", nrow(ttm_per_share_data), " rows, ", ncol(ttm_per_share_data), " columns\n")

# ---- SECTION 3: Validate parameters -----------------------------------------
if (!TICKER %in% ttm_per_share_data$ticker) {
  available_tickers <- unique(ttm_per_share_data$ticker)
  stop("Ticker '", TICKER, "' not found. Available tickers: ", paste(head(available_tickers, 10), collapse = ", "), "...")
}

if (!METRIC %in% names(ttm_per_share_data)) {
  available_metrics <- names(ttm_per_share_data)[grepl("_per_share$|^price_to_|^market_cap|^enterprise_value", names(ttm_per_share_data))]
  stop("Metric '", METRIC, "' not found. Common metrics: ", paste(head(available_metrics, 10), collapse = ", "), "...")
}

# ---- SECTION 4: Create Bar Plot for Selected Ticker and Metric -------------
cat("Creating bar plot for", TICKER, "-", METRIC, "...\n")

# Determine if metric is daily or quarterly frequency
# Daily metrics: price, volume, market_cap, effective_shares_outstanding
# Quarterly metrics: financial statement items (per_share metrics, ttm metrics)
is_daily_metric <- METRIC %in% c("close", "open", "high", "low", "volume", "market_cap",
                                 "effective_shares_outstanding", "commonStockSharesOutstanding")

# Filter data for selected ticker
ticker_data <- ttm_per_share_data %>%
  dplyr::filter(ticker == !!TICKER) %>%
  dplyr::filter(!is.na(!!rlang::sym(METRIC)))

if (is_daily_metric) {
  # For daily metrics, use recent data (last 2 years) to avoid overcrowding
  plot_data <- ticker_data %>%
    dplyr::filter(date >= Sys.Date() - 730) %>%  # Last 2 years
    dplyr::select(date, value = !!rlang::sym(METRIC)) %>%
    dplyr::arrange(date)

  date_col <- "date"
  plot_subtitle <- "Daily frequency (last 2 years)"

} else {
  # For quarterly metrics, use distinct fiscal periods
  plot_data <- ticker_data %>%
    dplyr::distinct(fiscalDateEnding, .keep_all = TRUE) %>%
    dplyr::select(fiscalDateEnding, value = !!rlang::sym(METRIC)) %>%
    dplyr::arrange(fiscalDateEnding)
    # dplyr::slice_tail(n = 20)  # Last 20 quarters

  date_col <- "fiscalDateEnding"
  plot_subtitle <- "Quarterly frequency (last 20 quarters)"
}

# Create bar plot
if (nrow(plot_data) == 0) {
  cat("No data available for", TICKER, "-", METRIC, "\n")
} else {

  # Format plot title
  plot_title_final <- PLOT_TITLE %||% paste0(TICKER, ": ", METRIC)

  # Create the plot
  p <- plot_data %>%
    ggplot2::ggplot(ggplot2::aes(x = !!rlang::sym(date_col), y = value)) +
    ggplot2::geom_col(fill = "steelblue", alpha = 0.7) +
    ggplot2::labs(
      title = plot_title_final,
      subtitle = plot_subtitle,
      x = ifelse(is_daily_metric, "Date", "Fiscal Date Ending"),
      y = METRIC
    ) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      plot.title = ggplot2::element_text(size = 14, face = "bold")
    )

  # Add formatting based on metric type
  if (is_daily_metric) {
    p <- p + ggplot2::scale_x_date(date_breaks = "3 months", date_labels = "%Y-%m")
  } else {
    p <- p + ggplot2::scale_x_date(date_breaks = "1 year", date_labels = "%Y")
  }

  # Format y-axis for large numbers
  if (max(plot_data$value, na.rm = TRUE) > 1e9) {
    p <- p + ggplot2::scale_y_continuous(labels = scales::label_number(scale = 1e-9, suffix = "B"))
  } else if (max(plot_data$value, na.rm = TRUE) > 1e6) {
    p <- p + ggplot2::scale_y_continuous(labels = scales::label_number(scale = 1e-6, suffix = "M"))
  }

  # Display the plot
  print(p)

  cat("Bar plot created with", nrow(plot_data), "data points\n")
}


