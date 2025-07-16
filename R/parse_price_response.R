#' Parse Price Response to Tibble
#'
#' @param response Raw httr response object
#' @param ticker Character. The equity ticker
#' @param datatype Character. Either "json" or "csv"
#'
#' @return A tibble with daily adjusted price data
#' @keywords internal
parse_price_response <- function(response, ticker, datatype) {
  if (datatype == "json") {
    # Parse JSON response
    content <- httr::content(response, as = "text", encoding = "UTF-8")
    data <- jsonlite::fromJSON(content)
    
    # Check for API error messages
    if ("Error Message" %in% names(data)) {
      stop("API Error: ", data$`Error Message`)
    }
    
    if ("Note" %in% names(data)) {
      warning("API Note: ", data$Note)
    }
    
    # Extract time series data
    time_series_key <- "Time Series (Daily)"
    if (!time_series_key %in% names(data)) {
      stop("Unexpected API response structure. Expected '", time_series_key, "' key not found.")
    }
    
    time_series <- data[[time_series_key]]
    
    # Convert to tibble using base R operations
    dates <- names(time_series)
    prices_list <- lapply(dates, function(date) {
      price_data <- time_series[[date]]
      data.frame(
        ticker = ticker,
        date = as.Date(date),
        open = as.numeric(price_data$`1. open`),
        high = as.numeric(price_data$`2. high`),
        low = as.numeric(price_data$`3. low`),
        close = as.numeric(price_data$`4. close`),
        adjusted_close = as.numeric(price_data$`5. adjusted close`),
        volume = as.numeric(price_data$`6. volume`),
        dividend_amount = as.numeric(price_data$`7. dividend amount`),
        split_coefficient = as.numeric(price_data$`8. split coefficient`),
        stringsAsFactors = FALSE
      )
    })
    
    prices_df <- dplyr::bind_rows(prices_list) %>%
      dplyr::arrange(date)
    
    return(prices_df)
    
  } else if (datatype == "csv") {
    # Parse CSV response
    content <- httr::content(response, as = "text", encoding = "UTF-8")
    
    # Read CSV data using base R
    prices_df <- read.csv(text = content, stringsAsFactors = FALSE) %>%
      dplyr::mutate(
        ticker = ticker,
        date = as.Date(timestamp)
      ) %>%
      dplyr::select(-timestamp) %>%
      dplyr::arrange(date)
    
    return(prices_df)
  }
}
