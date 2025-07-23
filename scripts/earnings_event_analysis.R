# =============================================================================
# Earnings Cycle Performance Analysis - Trading-Day Normalised
# =============================================================================
#
#   • Calculates cumulative price performance for the 30 trading days before
#     and after each earnings release (reportedDate) in a given year
#   • Normalises every series to 1 on the first trading day on/after the
#     reportedDate (t = 0)
#   • Aggregates across events (median, central-confidence ribbon)
#   • Optional ticker filter – defaults to S&P 500 constituents
#
#   NOTE: All offsets are now true TRADING-DAY counts, not calendar-day
#         differences, eliminating weekend / holiday distortions
# =============================================================================

# ---- CONFIGURATION PARAMETERS -----------------------------------------------
ANALYSIS_YEAR     <- 2025
DAYS_BEFORE       <- 30          # trading days
DAYS_AFTER        <- 30          # trading days
CONFIDENCE_LEVEL  <- 0.5        # central band width (e.g. .25 → 25th-75th pct)

# ---- TICKER FILTERING -------------------------------------------------------
# SELECTED_TICKERS <- c("AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA", "META")
# NULL ⇒ include every ticker in ttm_per_share_data
SELECTED_TICKERS  <- get_spy_constituents()

# ---- SECTION 1: Load helper functions ---------------------------------------
devtools::load_all()
set_ggplot_theme()

# ---- SECTION 2: Identify earnings events ------------------------------------
cat("Identifying earnings events for", ANALYSIS_YEAR, "...\n")

earnings_events <- ttm_per_share_data %>%
  dplyr::filter(
    !is.na(reportedDate),
    !is.na(adjusted_close),
    lubridate::year(reportedDate) == ANALYSIS_YEAR
  ) %>%
  { if (!is.null(SELECTED_TICKERS)) dplyr::filter(., ticker %in% SELECTED_TICKERS) else . } %>%
  dplyr::distinct(ticker, reportedDate, .keep_all = TRUE) %>%
  dplyr::select(ticker, reportedDate) %>%
  dplyr::arrange(ticker, reportedDate)

if (!is.null(SELECTED_TICKERS)) {
  cat("Filtering to", length(SELECTED_TICKERS), "selected tickers\n")
  missing_tickers <- setdiff(SELECTED_TICKERS, unique(earnings_events$ticker))
  if (length(missing_tickers) > 0) {
    cat("Warning: no earnings data for:", paste(missing_tickers, collapse = ", "), "\n")
  }
}

cat("Found", nrow(earnings_events), "earnings events in", ANALYSIS_YEAR, "\n")
cat("Covering", length(unique(earnings_events$ticker)), "unique stocks\n")

# ---- SECTION 3: Helper – window extraction ----------------------------------
calculate_earnings_cycle_performance <- function(ticker_sym, reported_date) {

  # pull roughly double-window to guarantee enough rows
  stock_data <- ttm_per_share_data %>%
    dplyr::filter(
      ticker == ticker_sym,
      !is.na(adjusted_close),
      date >= (reported_date - 120),
      date <= (reported_date + 120)
    ) %>%
    dplyr::arrange(date)

  if (nrow(stock_data) == 0) return(NULL)

  earnings_day_data <- stock_data %>%
    dplyr::filter(date >= reported_date) %>%
    dplyr::slice_head(n = 1)

  if (nrow(earnings_day_data) == 0) return(NULL)

  earnings_date_actual <- earnings_day_data$date[1]
  earnings_price       <- earnings_day_data$adjusted_close[1]

  stock_data_td <- stock_data %>%
    dplyr::mutate(trading_index = dplyr::row_number()) %>%
    dplyr::mutate(event_index   = trading_index[date == earnings_date_actual]) %>%
    dplyr::mutate(relative_day  = trading_index - event_index) %>%
    dplyr::filter(
      relative_day >= -DAYS_BEFORE,
      relative_day <=  DAYS_AFTER,
      relative_day != 0                      # exclude t = 0 (added later)
    ) %>%
    dplyr::mutate(
      reportedDate           = reported_date,
      earnings_date_actual   = earnings_date_actual,
      cumulative_performance = adjusted_close / earnings_price
    ) %>%
    dplyr::select(
      ticker,
      reportedDate,
      earnings_date_actual,
      relative_day,
      cumulative_performance
    )

  if (nrow(stock_data_td) == 0) return(NULL)

  stock_data_td
}

# ---- SECTION 4: Build performance matrix ------------------------------------
cat("Calculating performance windows around earnings events...\n")

all_performance_data <- earnings_events %>%
  split(seq_len(nrow(.))) %>%
  lapply(function(row) {
    calculate_earnings_cycle_performance(row$ticker, row$reportedDate)
  }) %>%
  dplyr::bind_rows()

actual_unique_stocks  <- length(unique(all_performance_data$ticker))
actual_earnings_events <- length(unique(
  paste(all_performance_data$ticker, all_performance_data$reportedDate)
))
total_data_points <- nrow(all_performance_data)

cat("Calculated windows for", actual_unique_stocks, "stocks\n")
cat("Across", actual_earnings_events, "earnings events |",
    scales::comma(total_data_points), "rows\n")

# ---- SECTION 5: Aggregate statistics ----------------------------------------
cat("Aggregating performance statistics...\n")

lower_prob <- (1 - CONFIDENCE_LEVEL) / 2
upper_prob <- 1 - lower_prob

aggregate_performance <- all_performance_data %>%
  dplyr::group_by(relative_day) %>%
  dplyr::summarise(
    median_performance = median(cumulative_performance, na.rm = TRUE),
    q_lower            = quantile(cumulative_performance, lower_prob, na.rm = TRUE),
    q_upper            = quantile(cumulative_performance, upper_prob, na.rm = TRUE),
    mean_performance   = mean(cumulative_performance,  na.rm = TRUE),
    event_count        = dplyr::n(),
    .groups            = "drop"
  ) %>%
  # add t = 0 anchor
  dplyr::bind_rows(
    data.frame(
      relative_day        = 0,
      median_performance  = 1,
      q_lower             = 1,
      q_upper             = 1,
      mean_performance    = 1,
      event_count         = actual_earnings_events
    )
  ) %>%
  dplyr::arrange(relative_day)

# ---- SECTION 6: Visualisation ----------------------------------------------
cat("Creating earnings-cycle plot …\n")

p_earnings_cycle <- aggregate_performance %>%
  ggplot2::ggplot(ggplot2::aes(x = relative_day)) +
  ggplot2::geom_ribbon(
    ggplot2::aes(ymin = q_lower, ymax = q_upper),
    fill  = "steelblue",
    alpha = 0.30
  ) +
  ggplot2::geom_line(
    ggplot2::aes(y = median_performance),
    colour = "steelblue",
    size   = 1.2
  ) +
  ggplot2::geom_hline(
    yintercept = 1,
    linetype   = "dashed",
    colour     = "red",
    alpha      = 0.7
  ) +
  ggplot2::geom_vline(
    xintercept = 0,
    linetype   = "dashed",
    colour     = "red",
    alpha      = 0.7
  ) +
  ggplot2::scale_x_continuous(
    breaks = seq(-DAYS_BEFORE, DAYS_AFTER, by = 10),
    labels = function(x) paste0("t", ifelse(x >= 0, "+", ""), x)
  ) +
  ggplot2::scale_y_continuous(
    labels = scales::percent_format(accuracy = 1, scale = 100, suffix = "%"),
    breaks = scales::pretty_breaks(n = 8)
  ) +
  ggplot2::labs(
    title    = paste("Earnings-Cycle Performance –", ANALYSIS_YEAR),
    subtitle = paste0(
      actual_unique_stocks, " stocks, ",
      actual_earnings_events, " events | ±", DAYS_BEFORE, " trading days | ",
      sprintf("%d–%d%% band",
              round(lower_prob * 100), round(upper_prob * 100))
    ),
    x        = "Trading Days Relative to Earnings Announcement",
    y        = "Cumulative Performance (100 % at t = 0)",
    caption  = paste0(
      "Based on adjusted close; ",
      scales::comma(total_data_points), " observations"
    )
  ) +
  ggplot2::theme(
    plot.title  = ggplot2::element_text(size = 14, face = "bold"),
    axis.title  = ggplot2::element_text(size = 12),
    legend.position = "none"
  )

print(p_earnings_cycle)

# ---- SECTION 7: Console summary --------------------------------------------
cat("\n=== EARNINGS-CYCLE ANALYSIS SUMMARY ===\n")
cat("Analysis Year           :", ANALYSIS_YEAR, "\n")
cat("Total Earnings Events   :", actual_earnings_events, "\n")
cat("Unique Stocks           :", actual_unique_stocks, "\n")
cat("Total Data Points       :", scales::comma(total_data_points), "\n")
cat("Window                  : t-", DAYS_BEFORE, " to t+", DAYS_AFTER, " trading days\n\n")

key_points <- aggregate_performance %>%
  dplyr::filter(relative_day %in% c(-30, -15, -5, -1, 1, 5, 15, 30))

cat("Key Performance Points (Median | central band):\n")
for (i in seq_len(nrow(key_points))) {
  row <- key_points[i, ]
  cat(sprintf(
    "t%+3d : %6.1f%%  [%6.1f%% to %6.1f%%]\n",
    row$relative_day,
    (row$median_performance - 1) * 100,
    (row$q_lower           - 1) * 100,
    (row$q_upper           - 1) * 100
  ))
}

cat("\nEarnings-cycle analysis completed!\n")


# ... existing code through Section 8 ...

# ---- SECTION 9: Create split performance visualizations ---------------------
cat("Creating split performance plots...\n")

# Function to create consistent plots - FIXED VERSION
create_earnings_plot <- function(agg_data, group_name, color_scheme, actual_event_count) {

  agg_data %>%
    ggplot2::ggplot(ggplot2::aes(x = relative_day)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = q_lower, ymax = q_upper),
      fill  = color_scheme,
      alpha = 0.30
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = median_performance),
      colour = color_scheme,
      size   = 1.2
    ) +
    ggplot2::geom_hline(
      yintercept = 1,
      linetype   = "dashed",
      colour     = "red",
      alpha      = 0.7
    ) +
    ggplot2::geom_vline(
      xintercept = 0,
      linetype   = "dashed",
      colour     = "red",
      alpha      = 0.7
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(-DAYS_BEFORE, DAYS_AFTER, by = 10),
      labels = function(x) paste0("t", ifelse(x >= 0, "+", ""), x)
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::percent_format(accuracy = 1, scale = 100, suffix = "%"),
      breaks = scales::pretty_breaks(n = 8)
    ) +
    ggplot2::labs(
      title    = paste("Earnings Cycle:", group_name, "Performance –", ANALYSIS_YEAR),
      subtitle = paste0(
        actual_event_count, " events | ±", DAYS_BEFORE, " trading days | ",
        sprintf("%d–%d%% band",
                round(lower_prob * 100), round(upper_prob * 100))
      ),
      x        = "Trading Days Relative to Earnings Announcement",
      y        = "Cumulative Performance (100% at t = 0)",
      caption  = paste0("Split by pre-earnings momentum (t-", DAYS_BEFORE, " to t-1)")
    ) +
    ggplot2::theme(
      plot.title     = ggplot2::element_text(size = 14, face = "bold"),
      axis.title     = ggplot2::element_text(size = 12),
      legend.position = "none"
    )
}

# Create plots for each group - PASS CORRECT EVENT COUNTS
p_bottom_half <- create_earnings_plot(
  bottom_half_aggregate,
  "Weak Pre-Earnings",
  "darkred",
  nrow(bottom_half_events)  # Correct event count
)

p_top_half <- create_earnings_plot(
  top_half_aggregate,
  "Strong Pre-Earnings",
  "darkgreen",
  nrow(top_half_events)  # Correct event count
)

# Display both plots
print(p_bottom_half)
print(p_top_half)

# ... rest of code unchanged ...
