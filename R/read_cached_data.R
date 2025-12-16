#' Read Cached Data
#'
#' Reads cached data from a CSV file and converts specified date columns to proper Date types.
#' This function handles the common issue of date columns being stored as character strings
#' in CSV files and needing conversion back to Date objects. This is a generic function
#' that works with any cached data type by specifying the relevant date columns.
#'
#' @param cache_file Path to the cache file (CSV format)
#' @param date_columns Character vector of column names that should be converted to Date type.
#'   Defaults to common date columns across different data types.
#' @return A data frame with properly formatted date columns
#' @export
#' 
read_cached_data <- function(cache_file, date_columns = c("date", "as_of_date")) {
  
  # Validate input
  validate_file_exists(cache_file, name = "cache_file")
  
  # Read the CSV file
  data <- read.csv(cache_file, stringsAsFactors = FALSE)
  
  # Convert date columns to Date type
  for (col in date_columns) {
    if (col %in% names(data)) {
      data[[col]] <- as.Date(data[[col]])
    }
  }
  
  return(data)
}
