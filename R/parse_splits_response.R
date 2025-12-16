#' Parse Alpha Vantage Splits Response
#'
#' Parses the JSON response from Alpha Vantage's SPLITS endpoint into a standardized data.frame.
#'
#' @param response Raw httr response object from Alpha Vantage API
#' @param ticker Character string representing the ticker symbol
#' @return A data.frame with columns: ticker, effective_date, split_factor, as_of_date
#' @export
#' 
parse_splits_response <- function(response, ticker) {
  
  # Parse JSON response
  content <- httr::content(response, "text", encoding = "UTF-8")
  response_content <- jsonlite::fromJSON(content)

  # Check if we got a proper JSON structure before using $ operator
  if (!is.list(response_content)) {
    stop("API returned non-JSON response for ticker ", ticker, ". Response: ",
         substr(as.character(response_content), 1, 200))
  }

  # Check for API error messages
  validate_api_response(response_content, ticker = ticker)
  
  if (is.null(response_content$data) || length(response_content$data) == 0) {
    # No split data available - return empty data.frame with correct structure
    cat("No split events found for ticker:", ticker, "\n")
    return(data.frame(
      ticker = character(0),
      effective_date = as.Date(character(0)),
      split_factor = numeric(0),
      as_of_date = as.Date(character(0)),
      stringsAsFactors = FALSE
    ))
  }
  
  # Extract split events from the data array
  split_events <- response_content$data
  
  # Convert data.frame to standardized format
  splits_df <- data.frame(
    ticker = ticker,
    effective_date = as.Date(split_events$effective_date),
    split_factor = as.numeric(split_events$split_factor),
    as_of_date = Sys.Date(),
    stringsAsFactors = FALSE
  )
  
  # Validate that we have the expected columns
  expected_cols <- c("ticker", "effective_date", "split_factor", "as_of_date")
  if (!all(expected_cols %in% names(splits_df))) {
    missing_cols <- setdiff(expected_cols, names(splits_df))
    stop("Missing expected columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Sort by effective_date (ascending - oldest first)
  splits_df <- splits_df[order(splits_df$effective_date), ]
  
  return(splits_df)
}
