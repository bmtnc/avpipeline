#' Load and Filter Financial Data
#'
#' Loads financial data from a CSV file using cached data reader and filters
#' by fiscal date ending. Validates that the loaded data contains required
#' date columns.
#'
#' @param file_path Character string path to the CSV file to load
#' @param min_date Date object specifying the minimum fiscal date ending to include.
#'   Defaults to December 31, 2004
#'
#' @return Data.frame containing the loaded and filtered financial data
#' @export
load_and_filter_financial_data <- function(
  file_path,
  min_date = as.Date("2004-12-31")
) {
  if (!is.character(file_path) || length(file_path) != 1) {
    stop(paste0(
      "Input 'file_path' must be a single character string. Received: ",
      class(file_path)[1],
      " of length ",
      length(file_path)
    ))
  }
  if (!file.exists(file_path)) {
    stop(paste0("File does not exist: ", file_path))
  }
  if (!inherits(min_date, "Date")) {
    stop(paste0(
      "Input 'min_date' must be a Date object. Received: ",
      class(min_date)[1]
    ))
  }

  # Define date columns for cached data reader
  date_columns <- c("fiscalDateEnding", "reportedDate", "as_of_date")

  # Load data using cached reader
  data <- read_cached_data(file_path, date_columns = date_columns)

  # Validate that loaded data contains required columns
  validate_df_cols(data, "fiscalDateEnding")

  # Filter by minimum date
  filtered_data <- data %>%
    dplyr::filter(fiscalDateEnding >= min_date)

  # Check that filtering didn't result in empty dataset
  if (nrow(filtered_data) == 0) {
    stop(paste0(
      "No data remains after filtering by min_date: ",
      as.character(min_date),
      ". Original data had ",
      nrow(data),
      " rows with date range from ",
      as.character(min(data$fiscalDateEnding, na.rm = TRUE)),
      " to ",
      as.character(max(data$fiscalDateEnding, na.rm = TRUE))
    ))
  }

  filtered_data
}
