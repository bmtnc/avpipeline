#' Combine and Process Price Data
#'
#' Combines existing cached data with newly fetched data and adds metadata columns
#' including row count, initial date, latest date, and as-of date for each ticker.
#'
#' @param existing_data Data frame with existing cached price data (can be NULL)
#' @param new_data Data frame with newly fetched price data
#' @param as_of_date Date, timestamp for when the data was pulled
#'
#' @return A data frame with combined data and metadata columns
#'
#' @examples
#' \dontrun{
#' existing_data <- read_cached_price_data("cache/price_data.csv")
#' new_data <- fetch_multiple_tickers(c("AAPL", "GOOGL"))
#' combined_data <- combine_and_process_price_data(existing_data, new_data, Sys.Date())
#' }
#'
#' @export
combine_and_process_price_data <- function(existing_data, new_data, as_of_date) {
  
  # Validate inputs
  if (is.null(new_data) || nrow(new_data) == 0) {
    stop("new_data cannot be NULL or empty")
  }
  
  # Process new data with metadata
  processed_new_data <- new_data %>% 
    dplyr::group_by(ticker) %>% 
    dplyr::add_count() %>% 
    dplyr::mutate(
      initial_date = min(date),
      latest_date = max(date),
      as_of_date = as_of_date
    ) %>% 
    dplyr::ungroup()
  
  # Combine with existing data if available
  if (!is.null(existing_data) && nrow(existing_data) > 0) {
    combined_data <- dplyr::bind_rows(existing_data, processed_new_data)
  } else {
    combined_data <- processed_new_data
  }
  
  return(combined_data)
}
