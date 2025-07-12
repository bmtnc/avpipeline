#' Read Cached Income Statement Data
#'
#' Reads cached income statement data from a CSV file and converts date columns to proper Date types.
#' This function handles the common issue of date columns being stored as character strings
#' in CSV files and needing conversion back to Date objects.
#'
#' @param cache_file Path to the cache file (CSV format)
#'
#' @return A data frame with properly formatted date columns
#'
#' @examples
#' \dontrun{
#' cached_data <- read_cached_income_statement_data("cache/income_statement_data.csv")
#' }
#'
#' @export
read_cached_income_statement_data <- function(cache_file) {
  
  # Validate input
  if (!file.exists(cache_file)) {
    stop("Cache file does not exist: ", cache_file)
  }
  
  # Read the CSV file
  data <- read.csv(cache_file, stringsAsFactors = FALSE)
  
  # Convert date columns to Date type
  date_columns <- c("fiscalDateEnding", "as_of_date")
  
  for (col in date_columns) {
    if (col %in% names(data)) {
      data[[col]] <- as.Date(data[[col]])
    }
  }
  
  return(data)
}
