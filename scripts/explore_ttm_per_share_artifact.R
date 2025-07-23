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
# TTM Per-Share Financial Artifact Explorer - DUAL PLOT VERSION
# =============================================================================
# ---- CONFIGURATION PARAMETERS -----------------------------------------------
TICKER <- "TXN"

# Fundamental KPI (quarterly bar plot)
FUNDAMENTAL_METRIC <- "nopat_ttm_per_share"
# FUNDAMENTAL_METRIC <- "fcf_ttm_per_share"
# FUNDAMENTAL_METRIC <- "ebitda_ttm_per_share"
# FUNDAMENTAL_METRIC <- "grossProfit_ttm_per_share"
# FUNDAMENTAL_METRIC <- "tangible_book_value_per_share"
# FUNDAMENTAL_METRIC <- "operatingCashflow_ttm_per_share"

# Valuation metric (daily line plot with callout)
VALUATION_METRIC <- "ev_nopat"
# VALUATION_METRIC <- "ev_ebitda"
# VALUATION_METRIC <- "ev_fcf"
# VALUATION_METRIC <- "ev_gp"
# VALUATION_METRIC <- "roic"
# VALUATION_METRIC <- "market_cap"
# VALUATION_METRIC <- "enterprise_value_per_share"

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
  "reportedDate",
  "calendar_quarter_ending"
)

# ttm_per_share_data <- read_cached_data_parquet(
# "cache/ttm_per_share_financial_artifact.parquet"
# )

# Calculate additional metrics
ttm_per_share_data <- ttm_per_share_data %>%
  dplyr::mutate(
    tangible_book_value_per_share = totalShareholderEquity_per_share -
      dplyr::coalesce(goodwill_per_share, 0),
    ev_ebitda = enterprise_value_per_share / ebitda_ttm_per_share,
    ev_nopat = enterprise_value_per_share / nopat_ttm_per_share,
    ev_fcf = enterprise_value_per_share / fcf_ttm_per_share,
    ev_gp = enterprise_value_per_share / grossProfit_ttm_per_share,
    roic = nopat_ttm_per_share / invested_capital_per_share * 100
  )
cat("Loaded dataset: ", nrow(ttm_per_share_data), " rows, ", ncol(ttm_per_share_data), " columns\n")
# ---- SECTION 3: Validate parameters -----------------------------------------
if (!TICKER %in% ttm_per_share_data$ticker) {
  available_tickers <- unique(ttm_per_share_data$ticker)
  stop("Ticker '", TICKER, "' not found. Available tickers: ", paste(head(available_tickers, 10), collapse = ", "), "...")
}

if (!FUNDAMENTAL_METRIC %in% names(ttm_per_share_data)) {
  stop("Fundamental metric '", FUNDAMENTAL_METRIC, "' not found in dataset")
}

if (!VALUATION_METRIC %in% names(ttm_per_share_data)) {
  stop("Valuation metric '", VALUATION_METRIC, "' not found in dataset")
}
# ---- SECTION 4: Create Fundamental KPI Bar Plot (Quarterly) ----------------
cat("Creating fundamental KPI bar plot for", TICKER, "-", FUNDAMENTAL_METRIC, "...\n")

fundamental_data <- ttm_per_share_data %>%
  dplyr::filter(ticker == !!TICKER) %>%
  dplyr::filter(!is.na(!!rlang::sym(FUNDAMENTAL_METRIC))) %>%
  dplyr::distinct(fiscalDateEnding, .keep_all = TRUE) %>%
  dplyr::select(fiscalDateEnding, value = !!rlang::sym(FUNDAMENTAL_METRIC)) %>%
  dplyr::arrange(fiscalDateEnding) %>%
  dplyr::slice_tail(n = 54)

if (nrow(fundamental_data) == 0) {
  cat("No fundamental data available for", TICKER, "-", FUNDAMENTAL_METRIC, "\n")
} else {
  p1 <- fundamental_data %>%
    ggplot2::ggplot(ggplot2::aes(x = fiscalDateEnding, y = value)) +
    ggplot2::geom_col(fill = "steelblue", alpha = 0.7) +
    ggplot2::labs(
      title = paste0(TICKER, ": ", FUNDAMENTAL_METRIC),
      # subtitle = "Quarterly",
      x = "Fiscal Date Ending",
      y = FUNDAMENTAL_METRIC
    ) +
    ggplot2::scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      plot.title = ggplot2::element_text(size = 14, face = "bold")
    )

  # Format y-axis for large numbers
  if (max(fundamental_data$value, na.rm = TRUE) > 1e9) {
    p1 <- p1 + ggplot2::scale_y_continuous(labels = scales::label_number(scale = 1e-9, suffix = "B"))
  } else if (max(fundamental_data$value, na.rm = TRUE) > 1e6) {
    p1 <- p1 + ggplot2::scale_y_continuous(labels = scales::label_number(scale = 1e-6, suffix = "M"))
  }

  print(p1)
  cat("Fundamental bar plot created with", nrow(fundamental_data), "data points\n")
}
# ---- SECTION 5: Create Valuation Line Plot (Daily with Callout) ------------
cat("Creating valuation line plot for", TICKER, "-", VALUATION_METRIC, "...\n")

valuation_data <- ttm_per_share_data %>%
  dplyr::filter(ticker == !!TICKER) %>%
  dplyr::filter(!is.na(!!rlang::sym(VALUATION_METRIC))) %>%
  dplyr::filter(date >= Sys.Date() - 5000) %>%
  dplyr::select(date, value = !!rlang::sym(VALUATION_METRIC)) %>%
  dplyr::arrange(date)

if (nrow(valuation_data) == 0) {
  cat("No valuation data available for", TICKER, "-", VALUATION_METRIC, "\n")
} else {
  # Get the most recent data point for callout
  most_recent <- valuation_data %>%
    dplyr::slice_tail(n = 1)

  p2 <- valuation_data %>%
    ggplot2::ggplot(ggplot2::aes(x = date, y = value)) +
    ggplot2::geom_line(color = "darkgreen", alpha = 0.8, size = 1) +
    # Add highlighted point for most recent data
    ggplot2::geom_point(
      data = most_recent,
      ggplot2::aes(x = date, y = value),
      color = "black",
      size = 3
    ) +
    # Add value label for most recent data
    ggplot2::geom_label(
      data = most_recent,
      ggplot2::aes(
        x = date,
        y = value,
        label = scales::comma(value, accuracy = 0.01)
      ),
      nudge_x = as.numeric(diff(range(valuation_data$date))) * 0.04,
      nudge_y = max(valuation_data$value, na.rm = TRUE) * 0.02,
      color = "black",
      fill = "white",
      alpha = 0.8,
      size = 2.5,
      fontface = "bold"
    ) +
    ggplot2::labs(
      title = paste0(TICKER, ": ", VALUATION_METRIC),
      # subtitle = "Daily frequency (last 2 years)",
      x = "Date",
      y = VALUATION_METRIC
    ) +
    # Expand x-axis to create space for the label
    ggplot2::coord_cartesian(
      xlim = c(
        min(valuation_data$date),
        max(valuation_data$date) + as.numeric(diff(range(valuation_data$date))) * 0.12
      )
    ) +
    ggplot2::scale_x_date(date_breaks = "1 year", date_labels = "%Y-%m") +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      plot.title = ggplot2::element_text(size = 14, face = "bold")
    )

  # Format y-axis for large numbers
  if (max(valuation_data$value, na.rm = TRUE) > 1e9) {
    p2 <- p2 + ggplot2::scale_y_continuous(labels = scales::label_number(scale = 1e-9, suffix = "B"))
  } else if (max(valuation_data$value, na.rm = TRUE) > 1e6) {
    p2 <- p2 + ggplot2::scale_y_continuous(labels = scales::label_number(scale = 1e-6, suffix = "M"))
  }

  print(p2)
  cat("Valuation line plot created with", nrow(valuation_data), "data points\n")
}
