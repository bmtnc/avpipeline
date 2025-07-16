#' Create Bar Plot for Time Series Financial Data
#'
#' Creates a bar plot using ggplot2 for time series financial data with date, ticker, and value columns.
#' Designed to work with unified financial datasets containing multiple tickers and metrics.
#'
#' @param data A data frame containing the financial data to plot
#' @param date_col Character string specifying the name of the date column
#' @param ticker_col Character string specifying the name of the ticker column
#' @param value_col Character string specifying the name of the value column to plot
#' @param title Character string for the plot title. If NULL, generates automatic title
#' @param y_label Character string for the y-axis label. If NULL, uses value_col name
#' @param date_breaks Character string specifying date breaks for x-axis (e.g., "1 year", "6 months")
#' @param bar_color Character string specifying the color of the bars (default: "steelblue")
#'
#' @return A ggplot2 object representing the bar plot
#' @export
create_bar_plot <- function(
    data,
    date_col,
    ticker_col,
    value_col,
    title = NULL,
    y_label = NULL,
    date_breaks = "1 year",
    bar_color = "steelblue"
) {

  # Validate column name parameters
  if (!is.character(date_col) || length(date_col) != 1) {
    stop(paste0("Argument 'date_col' must be a single character string. Received: ",
                class(date_col)[1], " of length ", length(date_col)))
  }

  if (!is.character(ticker_col) || length(ticker_col) != 1) {
    stop(paste0("Argument 'ticker_col' must be a single character string. Received: ",
                class(ticker_col)[1], " of length ", length(ticker_col)))
  }

  if (!is.character(value_col) || length(value_col) != 1) {
    stop(paste0("Argument 'value_col' must be a single character string. Received: ",
                class(value_col)[1], " of length ", length(value_col)))
  }

  # Validate data frame and required columns using helper function
  validate_df_cols(data, c(date_col, ticker_col, value_col))

  # Validate column types
  if (!inherits(data[[date_col]], "Date")) {
    stop(paste0("Date column '", date_col, "' must be of type Date. Received: ",
                class(data[[date_col]])[1]))
  }

  if (!is.numeric(data[[value_col]])) {
    stop(paste0("Value column '", value_col, "' must be numeric. Received: ",
                class(data[[value_col]])[1]))
  }

  # Validate optional parameters
  if (!is.null(title) && (!is.character(title) || length(title) != 1)) {
    stop(paste0("Argument 'title' must be NULL or a single character string. Received: ",
                class(title)[1], " of length ", length(title)))
  }

  if (!is.null(y_label) && (!is.character(y_label) || length(y_label) != 1)) {
    stop(paste0("Argument 'y_label' must be NULL or a single character string. Received: ",
                class(y_label)[1], " of length ", length(y_label)))
  }

  if (!is.character(date_breaks) || length(date_breaks) != 1) {
    stop(paste0("Argument 'date_breaks' must be a single character string. Received: ",
                class(date_breaks)[1], " of length ", length(date_breaks)))
  }

  if (!is.character(bar_color) || length(bar_color) != 1) {
    stop(paste0("Argument 'bar_color' must be a single character string. Received: ",
                class(bar_color)[1], " of length ", length(bar_color)))
  }

  # Remove rows with NA values in key columns
  clean_data <- data %>%
    dplyr::filter(!is.na(.data[[date_col]]),
                  !is.na(.data[[ticker_col]]),
                  !is.na(.data[[value_col]]))

  if (nrow(clean_data) == 0) {
    stop("No valid data rows after removing NA values in key columns")
  }

  # Generate automatic title if not provided
  if (is.null(title)) {
    unique_tickers <- unique(clean_data[[ticker_col]])
    if (length(unique_tickers) == 1) {
      title <- paste0(unique_tickers[1], " - ", stringr::str_to_title(gsub("_", " ", value_col)))
    } else {
      title <- paste0("Multiple Tickers - ", stringr::str_to_title(gsub("_", " ", value_col)))
    }
  }

  # Generate automatic y-axis label if not provided
  if (is.null(y_label)) {
    y_label <- stringr::str_to_title(gsub("_", " ", value_col))
  }

  # Create the bar plot
  plot <- clean_data %>%
    ggplot2::ggplot(ggplot2::aes(x = .data[[date_col]], y = .data[[value_col]])) +
    ggplot2::geom_col(fill = bar_color, alpha = 0.7) +
    ggplot2::scale_x_date(date_breaks = date_breaks,
                          date_labels = "%Y-%m",
                          expand = ggplot2::expansion(mult = c(0.02, 0.02))) +
    ggplot2::labs(title = title,
                  x = "Date",
                  y = y_label) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, size = 14, face = "bold"),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      axis.title = ggplot2::element_text(size = 12),
      panel.grid.minor = ggplot2::element_blank()
    )

  # Add faceting if multiple tickers
  unique_tickers <- unique(clean_data[[ticker_col]])
  if (length(unique_tickers) > 1) {
    plot <- plot + ggplot2::facet_wrap(stats::as.formula(paste0("~", ticker_col)),
                                       scales = "free_y",
                                       ncol = 2)
  }

  plot
}
