#' Print Data Status Summary
#'
#' Prints a human-readable summary of data freshness across all tickers.
#'
#' @param tracking tibble: Refresh tracking dataframe from s3_read_refresh_tracking()
#' @param reference_date Date: Date to compare against (default: Sys.Date())
#' @return invisible(NULL)
#' @export
print_data_status <- function(tracking, reference_date = Sys.Date()) {
  if (!is.data.frame(tracking)) {
    stop("print_data_status(): [tracking] must be a data.frame")
  }

  n_total <- nrow(tracking)
  if (n_total == 0) {
    message("No tickers in tracking")
    return(invisible(NULL))
  }

  summary <- get_data_status_summary(tracking, reference_date)

  has_full_price <- sum(isTRUE(summary$price_has_full), na.rm = TRUE)
  needs_full_price <- sum(isTRUE(summary$needs_price_full), na.rm = TRUE)
  needs_quarterly <- sum(isTRUE(summary$needs_quarterly), na.rm = TRUE)

  price_fresh <- sum(summary$price_days_stale <= 7, na.rm = TRUE)
  price_stale <- sum(summary$price_days_stale > 7 & summary$price_days_stale <= 90, na.rm = TRUE)
  price_very_stale <- sum(summary$price_days_stale > 90, na.rm = TRUE)
  price_missing <- sum(is.na(summary$price_days_stale))

  quarterly_fresh <- sum(summary$quarterly_days_stale <= 30, na.rm = TRUE)
  quarterly_stale <- sum(summary$quarterly_days_stale > 30 & summary$quarterly_days_stale <= 90, na.rm = TRUE)
  quarterly_very_stale <- sum(summary$quarterly_days_stale > 90, na.rm = TRUE)
  quarterly_missing <- sum(is.na(summary$quarterly_days_stale))

  message("=== DATA STATUS SUMMARY ===")
  message("Total tickers tracked: ", n_total)
  message("")
  message("PRICE DATA:")
  message("  Fresh (<=7d):     ", price_fresh)
  message("  Stale (8-90d):    ", price_stale)
  message("  Very stale (>90d): ", price_very_stale)
  message("  Missing:          ", price_missing)
  message("  Has full history: ", has_full_price)
  message("  Needs full fetch: ", needs_full_price)
  message("")
  message("QUARTERLY DATA:")
  message("  Fresh (<=30d):    ", quarterly_fresh)
  message("  Stale (31-90d):   ", quarterly_stale)
  message("  Very stale (>90d): ", quarterly_very_stale)
  message("  Missing:          ", quarterly_missing)
  message("  Needs refresh:    ", needs_quarterly)

  invisible(NULL)
}
