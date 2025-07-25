# =============================================================================
# Stock Price Decomposition Analysis - Enhanced Visualization
# =============================================================================
#
# Decomposes cumulative stock price changes into two main components:
# 1. Change in per-share fundamentals (with sub-breakdown)
# 2. Change in valuation multiple
#
# Within the fundamental component, shows breakdown between:
# - Actual fundamental growth (total company performance)
# - Share count changes (buybacks/issuances)
#
# Key Formula: Price = NOPAT per share × Multiple
# =============================================================================

# ---- CONFIGURATION PARAMETERS -----------------------------------------------
TICKER <- "ASML"

# Choose the fundamental metric for decomposition
FUNDAMENTAL_METRIC <- "nopat_ttm_per_share"
# FUNDAMENTAL_METRIC <- "grossProfit_ttm_per_share"
# FUNDAMENTAL_METRIC <- "fcf_ttm_per_share"
# FUNDAMENTAL_METRIC <- "ebitda_ttm_per_share"
# FUNDAMENTAL_METRIC <- "operatingCashflow_ttm_per_share"

# Analysis period (number of days back from most recent data)
# ANALYSIS_DAYS <- 1350
ANALYSIS_DAYS <- 1750

# Base date for decomposition (NULL = use first available date in period)
BASE_DATE <- NULL
# BASE_DATE <- as.Date("2020-01-01")

PLOT_TITLE <- NULL

# ---- SECTION 1: Load required functions -------------------------------------
set_ggplot_theme()

# ---- SECTION 2: Load and prepare data ---------------------------------------
cat("Loading TTM per-share financial artifact ...\n")

# ttm_per_share_data <- read_cached_data_parquet(
#   "cache/ttm_per_share_financial_artifact.parquet"
# )

cat("Loaded dataset: ", nrow(ttm_per_share_data), " rows, ", ncol(ttm_per_share_data), " columns\n")

# ---- SECTION 3: Validate parameters -----------------------------------------
if (!TICKER %in% ttm_per_share_data$ticker) {
  available_tickers <- unique(ttm_per_share_data$ticker)
  stop("Ticker '", TICKER, "' not found. Available tickers: ", paste(head(available_tickers, 10), collapse = ", "), "...")
}

if (!FUNDAMENTAL_METRIC %in% names(ttm_per_share_data)) {
  stop("Fundamental metric '", FUNDAMENTAL_METRIC, "' not found in dataset")
}

if (!"commonStockSharesOutstanding" %in% names(ttm_per_share_data)) {
  stop("commonStockSharesOutstanding not found in dataset - required for detailed decomposition")
}

# ---- SECTION 4: Prepare decomposition data ----------------------------------
cat("Preparing enhanced price decomposition data for", TICKER, "...\n")

# Filter and prepare base dataset
price_data <- ttm_per_share_data %>%
  dplyr::filter(ticker == !!TICKER) %>%
  dplyr::filter(!is.na(adjusted_close)) %>%
  dplyr::filter(!is.na(!!rlang::sym(FUNDAMENTAL_METRIC))) %>%
  dplyr::filter(!is.na(commonStockSharesOutstanding)) %>%
  dplyr::filter(!!rlang::sym(FUNDAMENTAL_METRIC) > 0) %>%  # Ensure positive fundamentals
  dplyr::filter(commonStockSharesOutstanding > 0) %>%  # Ensure positive share count
  dplyr::arrange(date) %>%
  dplyr::slice_tail(n = ANALYSIS_DAYS) %>%
  dplyr::select(
    date,
    price = adjusted_close,
    fundamental_per_share = !!rlang::sym(FUNDAMENTAL_METRIC),
    shares_outstanding = commonStockSharesOutstanding
  ) %>%
  dplyr::mutate(
    total_fundamental = fundamental_per_share * shares_outstanding,
    multiple = price / fundamental_per_share
  )

if (nrow(price_data) == 0) {
  stop("No valid data available for ", TICKER, " - ", FUNDAMENTAL_METRIC)
}

# Determine base date
if (is.null(BASE_DATE)) {
  base_date <- min(price_data$date)
} else {
  base_date <- BASE_DATE
  if (!base_date %in% price_data$date) {
    base_date <- price_data$date[which.min(abs(price_data$date - BASE_DATE))]
    cat("Adjusted base date to nearest available:", base_date, "\n")
  }
}

# Get base values
base_values <- price_data %>%
  dplyr::filter(date == base_date) %>%
  dplyr::slice(1)

base_price <- base_values$price
base_fundamental_per_share <- base_values$fundamental_per_share
base_shares <- base_values$shares_outstanding
base_total_fundamental <- base_values$total_fundamental
base_multiple <- base_values$multiple

cat("Base date:", as.character(base_date), "\n")
cat("Base price: $", round(base_price, 2), "\n")
cat("Base", FUNDAMENTAL_METRIC, ":", round(base_fundamental_per_share, 2), "\n")
cat("Base shares outstanding:", round(base_shares / 1e9, 2), "B\n")
cat("Base total", gsub("_ttm_per_share", "", FUNDAMENTAL_METRIC), ":", round(base_total_fundamental / 1e9, 2), "B\n")
cat("Base multiple:", round(base_multiple, 1), "x\n")

# ---- SECTION 5: Calculate decomposition (original + corrected sub-breakdown) ----
decomposition_data <- price_data %>%
  dplyr::filter(date >= base_date) %>%
  dplyr::mutate(
    # ORIGINAL TWO-LEVEL DECOMPOSITION (this math must be preserved)
    fundamental_per_share_change = fundamental_per_share - base_fundamental_per_share,
    multiple_change = multiple - base_multiple,
    price_change = price - base_price,

    # Main components (original working math)
    fundamental_contribution = fundamental_per_share_change * base_multiple,
    multiple_contribution = base_fundamental_per_share * multiple_change,

    # Interaction term (allocated proportionally as before)
    interaction_term = fundamental_per_share_change * multiple_change,

    # Adjust for interaction term (same as original)
    fundamental_contrib_adj = fundamental_contribution +
      ifelse(abs(fundamental_contribution) + abs(multiple_contribution) > 0,
             interaction_term * abs(fundamental_contribution) /
             (abs(fundamental_contribution) + abs(multiple_contribution)),
             interaction_term / 2),

    multiple_contrib_adj = multiple_contribution +
      ifelse(abs(fundamental_contribution) + abs(multiple_contribution) > 0,
             interaction_term * abs(multiple_contribution) /
             (abs(fundamental_contribution) + abs(multiple_contribution)),
             interaction_term / 2),

    # CORRECTED SUB-BREAKDOWN: Mathematically consistent decomposition
    # The exact relationship: current_per_share = current_total / current_shares
    actual_per_share_change = fundamental_per_share - base_fundamental_per_share,

    # Method 1: Direct allocation (mathematically exact)
    nopat_growth_per_share_effect = (total_fundamental - base_total_fundamental) / shares_outstanding,
    share_count_per_share_effect = actual_per_share_change - nopat_growth_per_share_effect,

    # Verification: these should sum exactly to actual_per_share_change
    per_share_decomp_check = nopat_growth_per_share_effect + share_count_per_share_effect,
    per_share_error = abs(per_share_decomp_check - actual_per_share_change),

    # Now allocate the fundamental_contrib_adj proportionally
    # Handle edge case where actual change is near zero
    nopat_growth_contribution = ifelse(abs(actual_per_share_change) > 1e-10,
                                      fundamental_contrib_adj * nopat_growth_per_share_effect / actual_per_share_change,
                                      fundamental_contrib_adj * 0.5),

    share_count_contribution = ifelse(abs(actual_per_share_change) > 1e-10,
                                     fundamental_contrib_adj * share_count_per_share_effect / actual_per_share_change,
                                     fundamental_contrib_adj * 0.5),

    # Final verification: sub-components should sum to fundamental contribution
    sub_decomp_check = nopat_growth_contribution + share_count_contribution,
    sub_decomp_error = abs(sub_decomp_check - fundamental_contrib_adj)
  ) %>%
  dplyr::select(
    date, price, fundamental_per_share, shares_outstanding, total_fundamental, multiple,
    price_change,
    fundamental_contribution = fundamental_contrib_adj,
    multiple_contribution = multiple_contrib_adj,
    nopat_growth_contribution,
    share_count_contribution,
    # Keep validation columns for debugging
    per_share_error,
    sub_decomp_error
  )



# ---- SECTION 6: Create enhanced stacked area chart ---------------------------
cat("Creating enhanced price decomposition visualization...\n")

# Get current data for callout and subtitle
current_data <- decomposition_data %>% dplyr::slice_tail(n = 1)

# Clear approach: Show actual dollar contributions
if (abs(current_data$price_change) > 0.01) {
  # Get the actual dollar contributions
  nopat_dollars <- current_data$nopat_growth_contribution
  share_dollars <- current_data$share_count_contribution
  valuation_dollars <- current_data$multiple_contribution

  # Create clean metric name from FUNDAMENTAL_METRIC
  metric_name <- tolower(gsub("_ttm_per_share", "", FUNDAMENTAL_METRIC))

  # Create dynamic labels based on direction of effects
  nopat_label <- paste0(
    ifelse(nopat_dollars >= 0, paste0(metric_name, " Growth"), paste0(metric_name, " Decline")),
    ": ", ifelse(nopat_dollars >= 0, "+", "-"), "$", round(abs(nopat_dollars), 1)
  )

  share_label <- paste0(
    ifelse(share_dollars >= 0, "Buybacks", "Dilution"),
    ": ", ifelse(share_dollars >= 0, "+", "-"), "$", round(abs(share_dollars), 1)
  )

  valuation_label <- paste0(
    ifelse(valuation_dollars >= 0, "Valuation Expansion", "Valuation Compression"),
    ": ", ifelse(valuation_dollars >= 0, "+", "-"), "$", round(abs(valuation_dollars), 1)
  )

  # Create subtitle with context
  total_change <- current_data$price_change
  direction_text <- ifelse(total_change > 0, "Gain", "Decline")

  subtitle_text <- paste0(
    "$", round(abs(total_change), 1), " Cumulative ", direction_text, " Contribution:", "\n",
    nopat_label, " | ", share_label, " | ", valuation_label
  )
} else {
  subtitle_text <- "No significant price change to analyze"
}

# Prepare data for enhanced stacked area chart
plot_data <- decomposition_data %>%
  dplyr::select(date, nopat_growth_contribution, share_count_contribution, multiple_contribution) %>%
  tidyr::pivot_longer(
    cols = c(nopat_growth_contribution, share_count_contribution, multiple_contribution),
    names_to = "component",
    values_to = "contribution"
  ) %>%
  dplyr::mutate(
    component = dplyr::case_when(
      component == "nopat_growth_contribution" ~ paste("∆", gsub("_ttm_per_share", "", FUNDAMENTAL_METRIC)),
      component == "share_count_contribution" ~ "∆ Share Count",
      component == "multiple_contribution" ~ "∆ Valuation",
      TRUE ~ component
    ),
    # Order for stacking
    component = factor(component, levels = c(
      paste("∆", gsub("_ttm_per_share", "", FUNDAMENTAL_METRIC)),
      "∆ Share Count",
      "∆ Valuation"
    ))
  )

# Create named color vector
fundamental_label <- paste("∆", gsub("_ttm_per_share", "", FUNDAMENTAL_METRIC))
shares_label <- "∆ Share Count"
multiple_label <- "∆ Valuation"

# Use similar colors for the fundamental sub-components, different for multiple
color_values <- c("steelblue", "lightblue", "darkgreen")
names(color_values) <- c(fundamental_label, shares_label, multiple_label)

# Create callout text for current metrics
callout_text <- paste0(
  "$", round(current_data$price, 2), "\n",
  "", round(current_data$multiple, 1), "x"
)

# Create the plot
p <- plot_data %>%
  ggplot2::ggplot(ggplot2::aes(x = date, y = contribution, fill = component)) +
  ggplot2::geom_area(alpha = 0.7, position = "stack") +
  ggplot2::geom_line(
    data = decomposition_data,
    ggplot2::aes(x = date, y = price_change),
    color = "black",
    linewidth = 1,
    inherit.aes = FALSE
  ) +
  # Add current metrics callout
  ggplot2::geom_point(
    data = current_data,
    ggplot2::aes(x = date, y = price_change),
    color = "black",
    size = 3,
    inherit.aes = FALSE
  ) +
  ggplot2::geom_label(
    data = current_data,
    ggplot2::aes(
      x = date,
      y = price_change,
      label = callout_text
    ),
    nudge_x = as.numeric(diff(range(decomposition_data$date))) * 0.06,
    nudge_y = max(decomposition_data$price_change, na.rm = TRUE) * 0.05,
    color = "black",
    fill = "white",
    alpha = 0.9,
    size = 3,
    fontface = "bold",
    lineheight = 0.9,
    inherit.aes = FALSE
  ) +
  ggplot2::scale_fill_manual(values = color_values) +
  ggplot2::labs(
    title = ifelse(is.null(PLOT_TITLE),
                   paste0(TICKER, ": Cumulative Price Change Decomposition"),
                   PLOT_TITLE),
    subtitle = subtitle_text,
    x = "Date",
    y = "Cumulative Price Change ($)",
    fill = "",
    caption = paste0(
      "Methodology: \n",
      "Price = EPS × Valuation Multiple\n",
      "Measure ∆ EPS and ∆ Valuation from start date\n",
      "∆ Price = (∆ EPS × base Valuation) + (base EPS × ∆ Valuation)\n",
      "∆ EPS = ∆ Total Earnings + ∆ Share Count Effects\n",
      "Start Date: ", base_date
    )
  ) +
  # Expand x-axis to create space for the callout
  ggplot2::coord_cartesian(
    xlim = c(
      min(decomposition_data$date),
      max(decomposition_data$date) + as.numeric(diff(range(decomposition_data$date))) * 0.15
    )
  ) +
  ggplot2::scale_x_date(date_breaks = "6 months", date_labels = "%Y") +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 0, hjust = 1),
    legend.position = "bottom",
    plot.title = ggplot2::element_text(size = 14, face = "bold", hjust = 0),
    plot.subtitle = ggplot2::element_text(size = 11, lineheight = 1.2, hjust = 0),
    plot.caption = ggplot2::element_text(hjust = 1)
  )

# Format y-axis
max_change <- max(abs(decomposition_data$price_change), na.rm = TRUE)
if (max_change > 100) {
  p <- p + ggplot2::scale_y_continuous(labels = scales::dollar_format())
} else {
  p <- p + ggplot2::scale_y_continuous(labels = scales::dollar_format(accuracy = 0.01))
}

print(p)

# ---- SECTION 7: VALIDATION AND QUALITY CHECKS ------------------------------
cat(paste0("\n", strrep("=", 60), "\n"))
cat("ENHANCED DECOMPOSITION VALIDATION CHECKS\n")
cat(paste0(strrep("=", 60), "\n"))

# Create validation dataset
validation_data <- decomposition_data %>%
  dplyr::mutate(
    # Check main decomposition (must equal original)
    main_total = fundamental_contribution + multiple_contribution,
    main_error = abs(main_total - price_change),

    # Check sub-decomposition
    sub_total = nopat_growth_contribution + share_count_contribution,
    sub_error = abs(sub_total - fundamental_contribution),

    # Check three-way total
    three_way_total = nopat_growth_contribution + share_count_contribution + multiple_contribution,
    three_way_error = abs(three_way_total - price_change),

    # Per-share consistency
    calculated_per_share_change = (nopat_growth_contribution + share_count_contribution) / base_multiple,
    actual_per_share_change = fundamental_per_share - base_fundamental_per_share,
    per_share_error = abs(calculated_per_share_change - actual_per_share_change)
  )

# ---- CHECK 1: Main Decomposition Accuracy -----------------------------------
cat("\n1. MAIN DECOMPOSITION ACCURACY (MUST BE PERFECT)\n")
cat(paste0(strrep("-", 45), "\n"))

max_main_error <- max(validation_data$main_error, na.rm = TRUE)
mean_main_error <- mean(validation_data$main_error, na.rm = TRUE)

cat("Max main decomposition error: $", round(max_main_error, 6), "\n")
cat("Mean main decomposition error: $", round(mean_main_error, 6), "\n")

main_correlation <- cor(validation_data$main_total, validation_data$price_change, use = "complete.obs")
cat("Main correlation (fund + multiple vs price): ", round(main_correlation, 8), "\n")

if (max_main_error < 0.01) {
  cat("✓ PASS: Main decomposition is accurate\n")
} else {
  cat("✗ FAIL: Main decomposition has errors\n")
}

# ---- CHECK 2: Sub-Decomposition Accuracy ------------------------------------
cat("\n2. SUB-DECOMPOSITION ACCURACY\n")
cat(paste0(strrep("-", 28), "\n"))

max_sub_error <- max(validation_data$sub_error, na.rm = TRUE)
mean_sub_error <- mean(validation_data$sub_error, na.rm = TRUE)

cat("Max sub-decomposition error: $", round(max_sub_error, 6), "\n")
cat("Mean sub-decomposition error: $", round(mean_sub_error, 6), "\n")

sub_correlation <- cor(validation_data$sub_total, validation_data$fundamental_contribution, use = "complete.obs")
cat("Sub correlation (nopat + shares vs fundamental): ", round(sub_correlation, 8), "\n")

if (max_sub_error < 0.01) {
  cat("✓ PASS: Sub-decomposition is accurate\n")
} else {
  cat("✗ FAIL: Sub-decomposition has errors\n")
}

# ---- CHECK 3: Three-Way Total -----------------------------------------------
cat("\n3. THREE-WAY TOTAL ACCURACY\n")
cat(paste0(strrep("-", 24), "\n"))

max_three_way_error <- max(validation_data$three_way_error, na.rm = TRUE)
mean_three_way_error <- mean(validation_data$three_way_error, na.rm = TRUE)

cat("Max three-way total error: $", round(max_three_way_error, 6), "\n")
cat("Mean three-way total error: $", round(mean_three_way_error, 6), "\n")

three_way_correlation <- cor(validation_data$three_way_total, validation_data$price_change, use = "complete.obs")
cat("Three-way correlation: ", round(three_way_correlation, 8), "\n")

if (max_three_way_error < 0.01) {
  cat("✓ PASS: Three-way total matches price change\n")
} else {
  cat("✗ FAIL: Three-way total has errors\n")
}

# ---- OVERALL VALIDATION SUMMARY ------------------------------------------
cat(paste0("\n", strrep("=", 60), "\n"))
cat("VALIDATION SUMMARY\n")
cat(paste0(strrep("=", 60), "\n"))

validation_score <- 0
if (max_main_error < 0.01) validation_score <- validation_score + 1
if (max_sub_error < 0.01) validation_score <- validation_score + 1
if (max_three_way_error < 0.01) validation_score <- validation_score + 1

cat("Validation Score: ", validation_score, "/3 (",
    round(validation_score/3*100, 1), "%)\n")

if (validation_score == 3) {
  cat("🎉 OVERALL: Enhanced decomposition validation PASSED\n")
} else {
  cat("⚠️ OVERALL: Enhanced decomposition validation FAILED - Review issues above\n")
}

cat(paste0(strrep("=", 60), "\n"))

# ---- SECTION 8: Summary statistics ------------------------------------------
cat("\n=== ENHANCED DECOMPOSITION SUMMARY ===\n")

current_data <- decomposition_data %>% dplyr::slice_tail(n = 1)

cat("Period:", as.character(base_date), "to", as.character(current_data$date), "\n")
cat("Total price change: $", round(current_data$price_change, 2), "\n\n")

cat("Main decomposition:\n")
cat("  - Fundamental contribution: $", round(current_data$fundamental_contribution, 2),
    " (", round(100 * current_data$fundamental_contribution / current_data$price_change, 1), "%)\n")
cat("  - Multiple contribution: $", round(current_data$multiple_contribution, 2),
    " (", round(100 * current_data$multiple_contribution / current_data$price_change, 1), "%)\n\n")

cat("Fundamental breakdown:\n")
cat("  - From total", gsub("_ttm_per_share", "", FUNDAMENTAL_METRIC), "growth: $",
    round(current_data$nopat_growth_contribution, 2),
    " (", round(100 * current_data$nopat_growth_contribution / current_data$price_change, 1), "%)\n")
cat("  - From share count changes: $", round(current_data$share_count_contribution, 2),
    " (", round(100 * current_data$share_count_contribution / current_data$price_change, 1), "%)\n")

cat("\nCurrent metrics:\n")
cat("  - Price: $", round(current_data$price, 2), "\n")
cat("  -", FUNDAMENTAL_METRIC, ":", round(current_data$fundamental_per_share, 2), "\n")
cat("  - Shares outstanding:", round(current_data$shares_outstanding / 1e9, 2), "B\n")
cat("  - Total", gsub("_ttm_per_share", "", FUNDAMENTAL_METRIC), ":", round(current_data$total_fundamental / 1e9, 2), "B\n")
cat("  - Multiple:", round(current_data$multiple, 1), "x\n")

# Change summary
share_change_pct <- (current_data$shares_outstanding - base_shares) / base_shares * 100
total_fundamental_change_pct <- (current_data$total_fundamental - base_total_fundamental) / base_total_fundamental * 100

cat("\nChange summary:\n")
cat("  - Share count change: ", round(share_change_pct, 1), "%\n")
cat("  - Total", gsub("_ttm_per_share", "", FUNDAMENTAL_METRIC), "change: ", round(total_fundamental_change_pct, 1), "%\n")

cat("\nData points:", nrow(decomposition_data), "\n")
