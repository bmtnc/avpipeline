#' Create Ticker Count Plot by Calendar Quarter
#'
#' Generates a bar chart showing the number of tickers with financial data
#' for each calendar quarter ending.
#'
#' @param financial_statements tibble: Financial statements data with ticker and calendar_quarter_ending columns
#' @return ggplot: Bar chart visualization of ticker counts by calendar quarter
#' @keywords internal
create_ticker_count_plot <- function(financial_statements) {
  if (!is.data.frame(financial_statements)) {
    stop(paste0("create_ticker_count_plot(): [financial_statements] must be a data.frame, not ", class(financial_statements)[1]))
  }
  
  required_cols <- c("ticker", "calendar_quarter_ending")
  missing_cols <- setdiff(required_cols, names(financial_statements))
  if (length(missing_cols) > 0) {
    stop(paste0("create_ticker_count_plot(): [financial_statements] missing required columns: ", paste(missing_cols, collapse = ", ")))
  }
  
  message(paste0("Creating ticker count visualization with standardized dates..."))
  
  standardized_ticker_counts <- financial_statements %>%
    dplyr::group_by(calendar_quarter_ending) %>%
    dplyr::summarise(
      ticker_count = dplyr::n_distinct(ticker),
      .groups = "drop"
    ) %>%
    dplyr::arrange(calendar_quarter_ending)
  
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
    ggplot2::scale_y_continuous(
      expand = c(0, 0),
      limits = c(0, max(standardized_ticker_counts$ticker_count) * 1.05)
    )
  
  standardized_plot
}
