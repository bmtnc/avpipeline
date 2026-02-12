#!/usr/bin/env Rscript

# ============================================================================
# Fetch Historical Options & Build IV Term Structure
# ============================================================================
# Fetches option chains for a set of tickers, builds implied volatility
# term structures, and uploads artifacts to S3. Plots IV over time for
# a selected ticker at the end.
#
# Usage:
#   Rscript scripts/run_options_iv.R
# ============================================================================

devtools::load_all()

# ============================================================================
# PARAMETERS
# ============================================================================

tickers <- c("AAPL", "MSFT", "GOOGL")
n_weeks <- 52L
bucket_name <- "avpipeline-artifacts-prod"
region <- "us-east-1"
tenors <- c(30, 60, 90, 180, 365)
moneyness_threshold <- 0.05

# Ticker to plot
plot_ticker <- "AAPL"

# ============================================================================
# FETCH & BUILD
# ============================================================================

result <- fetch_options_and_build_artifact(
  tickers = tickers,
  n_weeks = n_weeks,
  bucket_name = bucket_name,
  region = region,
  tenors = tenors,
  moneyness_threshold = moneyness_threshold
)

cat(sprintf(
  "\nResult: %d raw rows, %d interpolated rows | succeeded: %s | failed: %s\n",
  result$raw_rows, result$interpolated_rows,
  paste(result$tickers_succeeded, collapse = ", "),
  if (length(result$tickers_failed) == 0) "none" else paste(result$tickers_failed, collapse = ", ")
))

# ============================================================================
# PLOT: IMPLIED VOL OVER TIME BY TENOR
# ============================================================================

artifact_date <- format(Sys.Date(), "%Y-%m-%d")
interp <- load_options_interpolated_term_structure(bucket_name, artifact_date, region)

plot_data <- interp %>%
  dplyr::filter(ticker == plot_ticker, !is.na(iv))

if (nrow(plot_data) == 0) {
  message(sprintf("No interpolated IV data for %s — skipping plot.", plot_ticker))
} else {
  plot_data <- plot_data %>%
    dplyr::mutate(tenor_label = paste0(tenor_days, "d"))

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(
    x = observation_date, y = iv, color = tenor_label
  )) +
    ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::geom_point(size = 1.2) +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    ggplot2::labs(
      title = sprintf("%s — Implied Volatility Over Time", plot_ticker),
      x = "Observation Date",
      y = "ATM Implied Volatility",
      color = "Tenor"
    ) +
    ggplot2::theme_minimal(base_size = 13)

  print(p)
}
