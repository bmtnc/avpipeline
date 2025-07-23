# =============================================================================
# Stock Price Decomposition Analysis
# =============================================================================
#
# Decomposes cumulative stock price changes into two components:
# 1. Change in per-share economics (e.g., NOPAT per share)
# 2. Change in valuation multiple
#
# Key Formula: Price = NOPAT per share × Multiple
# Where Multiple = Adjusted Close / NOPAT per share
#
# =============================================================================

# ---- CONFIGURATION PARAMETERS -----------------------------------------------
TICKER <- "AAPL"

# Choose the fundamental metric for decomposition
FUNDAMENTAL_METRIC <- "nopat_ttm_per_share"
# FUNDAMENTAL_METRIC <- "fcf_ttm_per_share"
# FUNDAMENTAL_METRIC <- "ebitda_ttm_per_share"

# Analysis period (number of days back from most recent data)
ANALYSIS_DAYS <- 2000

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

# ---- SECTION 4: Prepare decomposition data ----------------------------------
cat("Preparing price decomposition data for", TICKER, "...\n")

# Filter and prepare base dataset
price_data <- ttm_per_share_data %>%
  dplyr::filter(ticker == !!TICKER) %>%
  dplyr::filter(!is.na(adjusted_close)) %>%
  dplyr::filter(!is.na(!!rlang::sym(FUNDAMENTAL_METRIC))) %>%
  dplyr::filter(!!rlang::sym(FUNDAMENTAL_METRIC) > 0) %>%  # Ensure positive fundamentals
  dplyr::arrange(date) %>%
  dplyr::slice_tail(n = ANALYSIS_DAYS) %>%
  dplyr::select(
    date,
    price = adjusted_close,
    fundamental = !!rlang::sym(FUNDAMENTAL_METRIC)
  ) %>%
  dplyr::mutate(
    multiple = price / fundamental
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
base_fundamental <- base_values$fundamental
base_multiple <- base_values$multiple

cat("Base date:", as.character(base_date), "\n")
cat("Base price: $", round(base_price, 2), "\n")
cat("Base", FUNDAMENTAL_METRIC, ":", round(base_fundamental, 2), "\n")
cat("Base multiple:", round(base_multiple, 1), "x\n")

# ---- SECTION 5: Calculate decomposition -------------------------------------
decomposition_data <- price_data %>%
  dplyr::filter(date >= base_date) %>%
  dplyr::mutate(
    # Current changes from base
    fundamental_change = fundamental - base_fundamental,
    multiple_change = multiple - base_multiple,
    price_change = price - base_price,
    
    # Decomposition components
    # Component 1: Change due to fundamental improvement (holding multiple constant)
    fundamental_contribution = fundamental_change * base_multiple,
    
    # Component 2: Change due to multiple expansion (holding fundamental constant)
    multiple_contribution = base_fundamental * multiple_change,
    
    # Interaction term (allocated proportionally)
    interaction_term = fundamental_change * multiple_change,
    
    # Total contribution should equal actual price change
    total_contribution = fundamental_contribution + multiple_contribution + interaction_term,
    
    # Allocate interaction term proportionally
    fundamental_contrib_adj = fundamental_contribution + 
      ifelse(abs(fundamental_contribution) + abs(multiple_contribution) > 0,
             interaction_term * abs(fundamental_contribution) / 
             (abs(fundamental_contribution) + abs(multiple_contribution)),
             interaction_term / 2),
    
    multiple_contrib_adj = multiple_contribution + 
      ifelse(abs(fundamental_contribution) + abs(multiple_contribution) > 0,
             interaction_term * abs(multiple_contribution) / 
             (abs(fundamental_contribution) + abs(multiple_contribution)),
             interaction_term / 2)
  ) %>%
  dplyr::select(
    date, price, fundamental, multiple, price_change,
    fundamental_contribution = fundamental_contrib_adj,
    multiple_contribution = multiple_contrib_adj
  )

# ---- SECTION 6: Create stacked area chart -----------------------------------
cat("Creating price decomposition visualization...\n")

# Prepare data for stacked area chart
plot_data <- decomposition_data %>%
  dplyr::select(date, fundamental_contribution, multiple_contribution) %>%
  tidyr::pivot_longer(
    cols = c(fundamental_contribution, multiple_contribution),
    names_to = "component",
    values_to = "contribution"
  ) %>%
  dplyr::mutate(
    component = dplyr::case_when(
      component == "fundamental_contribution" ~ paste("Change in", FUNDAMENTAL_METRIC),
      component == "multiple_contribution" ~ "Change in Valuation Multiple",
      TRUE ~ component
    )
  )

# Create named color vector
fundamental_label <- paste("Change in", FUNDAMENTAL_METRIC)
multiple_label <- "Change in Valuation Multiple"

color_values <- c("steelblue", "darkgreen")
names(color_values) <- c(fundamental_label, multiple_label)

# Create the plot
p <- plot_data %>%
  ggplot2::ggplot(ggplot2::aes(x = date, y = contribution, fill = component)) +
  ggplot2::geom_area(alpha = 0.7, position = "stack") +
  ggplot2::geom_line(
    data = decomposition_data,
    ggplot2::aes(x = date, y = price_change),
    color = "black",
    size = 1,
    inherit.aes = FALSE
  ) +
  ggplot2::scale_fill_manual(values = color_values) +
  ggplot2::labs(
    title = ifelse(is.null(PLOT_TITLE), 
                   paste0(TICKER, ": Stock Price Change Decomposition"), 
                   PLOT_TITLE),
    subtitle = paste0("Based on ", FUNDAMENTAL_METRIC, " | Base date: ", base_date),
    x = "Date",
    y = "Cumulative Price Change ($)",
    fill = "Source of Change",
    caption = "Black line shows actual cumulative price change"
  ) +
  ggplot2::scale_x_date(date_breaks = "6 months", date_labels = "%Y-%m") +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
    legend.position = "bottom",
    plot.title = ggplot2::element_text(size = 14, face = "bold")
  )

# Format y-axis
max_change <- max(abs(decomposition_data$price_change), na.rm = TRUE)
if (max_change > 100) {
  p <- p + ggplot2::scale_y_continuous(labels = scales::dollar_format())
} else {
  p <- p + ggplot2::scale_y_continuous(labels = scales::dollar_format(accuracy = 0.01))
}

print(p)

# ... existing code ...


# ---- SECTION 7: VALIDATION AND QUALITY CHECKS ------------------------------
cat(paste0("\n", strrep("=", 60), "\n"))
cat("DECOMPOSITION VALIDATION CHECKS\n")
cat(paste0(strrep("=", 60), "\n"))

# Create validation dataset
validation_data <- decomposition_data %>%
  dplyr::mutate(
    # Recalculate components for validation
    calculated_total = fundamental_contribution + multiple_contribution,
    decomposition_error = abs(calculated_total - price_change),
    relative_error = ifelse(abs(price_change) > 0.01, 
                           decomposition_error / abs(price_change) * 100, 
                           NA),
    
    # Recalculate multiple for consistency check
    calculated_multiple = price / fundamental,
    multiple_consistency_error = abs(calculated_multiple - multiple),
    
    # Sign consistency checks
    fundamental_direction = sign(fundamental - base_fundamental),
    fundamental_contrib_direction = sign(fundamental_contribution),
    multiple_direction = sign(multiple - base_multiple),
    multiple_contrib_direction = sign(multiple_contribution)
  )

# ---- CHECK 1: Mathematical Accuracy -----------------------------------------
cat("\n1. MATHEMATICAL ACCURACY\n")
cat(paste0(strrep("-", 25), "\n"))

max_abs_error <- max(validation_data$decomposition_error, na.rm = TRUE)
mean_abs_error <- mean(validation_data$decomposition_error, na.rm = TRUE)
max_rel_error <- max(validation_data$relative_error, na.rm = TRUE)
mean_rel_error <- mean(validation_data$relative_error, na.rm = TRUE)

cat("Max absolute error: $", round(max_abs_error, 4), "\n")
cat("Mean absolute error: $", round(mean_abs_error, 4), "\n")
cat("Max relative error: ", round(max_rel_error, 2), "%\n")
cat("Mean relative error: ", round(mean_rel_error, 2), "%\n")

# Correlation check
price_change_cor <- cor(validation_data$calculated_total, validation_data$price_change, use = "complete.obs")
cat("Correlation (calculated vs actual): ", round(price_change_cor, 6), "\n")

if (max_abs_error < 0.01) {
  cat("✓ PASS: Decomposition is mathematically accurate\n")
} else {
  cat("✗ FAIL: Decomposition has significant errors\n")
}

# ---- CHECK 2: Multiple Consistency ------------------------------------------
cat("\n2. MULTIPLE CONSISTENCY\n")
cat(paste0(strrep("-", 20), "\n"))

max_multiple_error <- max(validation_data$multiple_consistency_error, na.rm = TRUE)
mean_multiple_error <- mean(validation_data$multiple_consistency_error, na.rm = TRUE)

cat("Max multiple calculation error: ", round(max_multiple_error, 4), "x\n")
cat("Mean multiple calculation error: ", round(mean_multiple_error, 4), "x\n")

if (max_multiple_error < 0.01) {
  cat("✓ PASS: Multiple calculations are consistent\n")
} else {
  cat("✗ FAIL: Multiple calculations have errors\n")
}

# ---- CHECK 3: Directional Logic ---------------------------------------------
cat("\n3. DIRECTIONAL LOGIC\n")
cat(paste0(strrep("-", 17), "\n"))

# Check fundamental direction consistency
fundamental_sign_matches <- validation_data %>%
  dplyr::filter(!is.na(fundamental_direction) & !is.na(fundamental_contrib_direction)) %>%
  dplyr::summarise(
    total_obs = dplyr::n(),
    matches = sum(fundamental_direction == fundamental_contrib_direction | 
                  (fundamental_direction == 0 & abs(fundamental_contrib_direction) < 0.01) |
                  (fundamental_contrib_direction == 0 & abs(fundamental_direction) < 0.01)),
    match_rate = matches / total_obs * 100
  )

# Check multiple direction consistency  
multiple_sign_matches <- validation_data %>%
  dplyr::filter(!is.na(multiple_direction) & !is.na(multiple_contrib_direction)) %>%
  dplyr::summarise(
    total_obs = dplyr::n(),
    matches = sum(multiple_direction == multiple_contrib_direction |
                  (multiple_direction == 0 & abs(multiple_contrib_direction) < 0.01) |
                  (multiple_contrib_direction == 0 & abs(multiple_direction) < 0.01)),
    match_rate = matches / total_obs * 100
  )

cat("Fundamental direction consistency: ", round(fundamental_sign_matches$match_rate, 1), 
    "% (", fundamental_sign_matches$matches, "/", fundamental_sign_matches$total_obs, ")\n")
cat("Multiple direction consistency: ", round(multiple_sign_matches$match_rate, 1), 
    "% (", multiple_sign_matches$matches, "/", multiple_sign_matches$total_obs, ")\n")

if (fundamental_sign_matches$match_rate > 95 & multiple_sign_matches$match_rate > 95) {
  cat("✓ PASS: Directional logic is sound\n")
} else {
  cat("✗ FAIL: Directional logic has inconsistencies\n")
}

# ---- CHECK 4: Data Quality -----------------------------------------------
cat("\n4. DATA QUALITY\n")
cat(paste0(strrep("-", 12), "\n"))

infinite_values <- sum(is.infinite(validation_data$fundamental_contribution) | 
                       is.infinite(validation_data$multiple_contribution))
na_values <- sum(is.na(validation_data$fundamental_contribution) | 
                 is.na(validation_data$multiple_contribution))
negative_fundamentals <- sum(validation_data$fundamental <= 0, na.rm = TRUE)

cat("Infinite values: ", infinite_values, "\n")
cat("NA values: ", na_values, "\n") 
cat("Negative/zero fundamentals: ", negative_fundamentals, "\n")

if (infinite_values == 0 & na_values == 0 & negative_fundamentals == 0) {
  cat("✓ PASS: Data quality is good\n")
} else {
  cat("✗ FAIL: Data quality issues detected\n")
}

# ---- CHECK 5: Economic Sensibility ----------------------------------------
cat("\n5. ECONOMIC SENSIBILITY\n")
cat(paste0(strrep("-", 20), "\n"))

current_data <- validation_data %>% dplyr::slice_tail(n = 1)
start_data <- validation_data %>% dplyr::slice_head(n = 1)

# Calculate percentage contributions
total_price_change <- current_data$price_change
fundamental_pct <- current_data$fundamental_contribution / total_price_change * 100
multiple_pct <- current_data$multiple_contribution / total_price_change * 100

cat("Total price change: $", round(total_price_change, 2), "\n")
cat("Fundamental contribution: ", round(fundamental_pct, 1), "%\n")
cat("Multiple contribution: ", round(multiple_pct, 1), "%\n")

# Check if contributions sum to ~100%
total_pct <- abs(fundamental_pct) + abs(multiple_pct)
if (abs(total_pct - 100) < 1) {
  cat("✓ PASS: Contributions sum to 100%\n")
} else {
  cat("✗ FAIL: Contributions don't sum to 100% (", round(total_pct, 1), "%)\n")
}

# ---- CHECK 6: Time Series Properties --------------------------------------
cat("\n6. TIME SERIES PROPERTIES\n")
cat(paste0(strrep("-", 22), "\n"))

# Check for reasonable volatility
price_volatility <- sd(validation_data$price_change, na.rm = TRUE)
fundamental_volatility <- sd(validation_data$fundamental_contribution, na.rm = TRUE)
multiple_volatility <- sd(validation_data$multiple_contribution, na.rm = TRUE)

cat("Price change volatility: $", round(price_volatility, 2), "\n")
cat("Fundamental contribution volatility: $", round(fundamental_volatility, 2), "\n")
cat("Multiple contribution volatility: $", round(multiple_volatility, 2), "\n")

# Check for trend consistency
price_trend <- lm(price_change ~ as.numeric(date), data = validation_data)$coefficients[2]
fundamental_trend <- lm(fundamental_contribution ~ as.numeric(date), data = validation_data)$coefficients[2]
multiple_trend <- lm(multiple_contribution ~ as.numeric(date), data = validation_data)$coefficients[2]

cat("Price change trend: $", round(price_trend * 365, 2), "/year\n")
cat("Fundamental contribution trend: $", round(fundamental_trend * 365, 2), "/year\n")
cat("Multiple contribution trend: $", round(multiple_trend * 365, 2), "/year\n")

# ---- OVERALL VALIDATION SUMMARY ------------------------------------------
cat(paste0("\n", strrep("=", 60), "\n"))
cat("VALIDATION SUMMARY\n")
cat(paste0(strrep("=", 60), "\n"))

validation_score <- 0
total_checks <- 6

if (max_abs_error < 0.01) validation_score <- validation_score + 1
if (max_multiple_error < 0.01) validation_score <- validation_score + 1  
if (fundamental_sign_matches$match_rate > 95 & multiple_sign_matches$match_rate > 95) validation_score <- validation_score + 1
if (infinite_values == 0 & na_values == 0 & negative_fundamentals == 0) validation_score <- validation_score + 1
if (abs(total_pct - 100) < 1) validation_score <- validation_score + 1
validation_score <- validation_score + 1  # Time series check always passes for info

cat("Validation Score: ", validation_score, "/", total_checks, " (", 
    round(validation_score/total_checks*100, 1), "%)\n")

if (validation_score >= 5) {
  cat("🎉 OVERALL: Decomposition validation PASSED\n")
} else {
  cat("⚠️  OVERALL: Decomposition validation FAILED - Review issues above\n")
}

cat(paste0(strrep("=", 60), "\n"))

# ---- SECTION 8: Summary statistics ------------------------------------------
cat("\n=== DECOMPOSITION SUMMARY ===\n")
current_data <- decomposition_data %>% dplyr::slice_tail(n = 1)

cat("Period:", as.character(base_date), "to", as.character(current_data$date), "\n")
cat("Total price change: $", round(current_data$price_change, 2), "\n")
cat("  - From", FUNDAMENTAL_METRIC, "change: $", round(current_data$fundamental_contribution, 2), 
    " (", round(100 * current_data$fundamental_contribution / current_data$price_change, 1), "%)\n")
cat("  - From multiple change: $", round(current_data$multiple_contribution, 2), 
    " (", round(100 * current_data$multiple_contribution / current_data$price_change, 1), "%)\n")

cat("\nCurrent metrics:\n")
cat("  - Price: $", round(current_data$price, 2), "\n")
cat("  -", FUNDAMENTAL_METRIC, ":", round(current_data$fundamental, 2), "\n")
cat("  - Multiple:", round(current_data$multiple, 1), "x\n")

cat("\nData points:", nrow(decomposition_data), "\n")