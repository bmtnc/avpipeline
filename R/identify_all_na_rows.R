#' Remove Rows with All NA Financial Columns
#'
#' Identifies and removes observations where all financial metric columns contain NA values,
#' keeping only records that have at least some financial data available. Reports details
#' about removed observations for data quality monitoring.
#'
#' @param data A data frame containing financial data
#' @param financial_cols Character vector of column names representing financial metrics
#' @param statement_type Character string describing the type of financial statement for reporting
#'
#' @return A data frame with rows containing all NA financial columns removed
#' @export
identify_all_na_rows <- function(data, financial_cols, statement_type) {
  if (!is.character(financial_cols)) {
    stop(paste0(
      "financial_cols must be a character vector. Received: ",
      class(financial_cols)[1]
    ))
  }
  validate_character_scalar(statement_type, name = "statement_type")

  if (length(financial_cols) == 0) {
    cat("Warning: No financial columns found for", statement_type, "\n")
    return(data)
  }

  # Validate data frame and required columns exist
  validate_df_cols(data, financial_cols)

  original_count <- nrow(data)

  # Remove rows where all financial columns are NA using dplyr::if_all()
  cleaned_data <- data %>%
    dplyr::filter(!dplyr::if_all(dplyr::all_of(financial_cols), is.na))

  removed_count <- original_count - nrow(cleaned_data)

  if (removed_count > 0) {
    cat(
      "- Removed",
      removed_count,
      "observations from",
      statement_type,
      "with all NA financial columns\n"
    )

    # Show sample of removed ticker-date combinations if columns exist
    required_reporting_cols <- c("ticker", "fiscalDateEnding")
    if (all(required_reporting_cols %in% names(data))) {
      removed_observations <- data %>%
        dplyr::filter(dplyr::if_all(dplyr::all_of(financial_cols), is.na)) %>%
        dplyr::select(dplyr::all_of(required_reporting_cols))

      if (nrow(removed_observations) > 0) {
        removed_tickers <- unique(removed_observations$ticker)
        cat(
          "  Affected tickers:",
          length(removed_tickers),
          "(",
          paste(head(removed_tickers, 5), collapse = ", ")
        )
        if (length(removed_tickers) > 5) {
          cat(", ...")
        }
        cat(")\n")
      }
    }
  }

  cleaned_data
}
