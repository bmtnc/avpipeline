#' Read Cached Income Statement Data
#'
#' Reads cached income statement data from a CSV file and converts date columns to proper Date types.
#' This function is a wrapper around the generic read_cached_data() function with
#' income statement-specific date columns specified.
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
  
  # Use the generic function with income statement-specific date columns
  read_cached_data(
    cache_file = cache_file,
    date_columns = c("fiscalDateEnding", "as_of_date")
  )
}
