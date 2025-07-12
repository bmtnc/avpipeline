#' Read Cached Price Data
#'
#' Reads cached price data from a CSV file and converts date columns to proper Date types.
#' This function is a wrapper around the generic read_cached_data() function with
#' price-specific date columns specified.
#'
#' @param cache_file Path to the cache file (CSV format)
#'
#' @return A data frame with properly formatted date columns
#'
#' @examples
#' \dontrun{
#' cached_data <- read_cached_price_data("cache/price_data.csv")
#' }
#'
#' @export
read_cached_price_data <- function(cache_file) {
  
  # Use the generic function with price-specific date columns
  read_cached_data(
    cache_file = cache_file,
    date_columns = c("date", "initial_date", "latest_date", "as_of_date")
  )
}
