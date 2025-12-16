#' Parse ETF profile API response and extract ticker symbols
#'
#' @param response Raw httr response object from Alpha Vantage ETF profile API
#'
#' @return Character vector of ticker symbols from ETF holdings
#' @keywords internal
parse_etf_profile_response <- function(response) {
  # Get response content
  content <- httr::content(response, as = "text", encoding = "UTF-8")

  # Parse JSON response
  parsed_data <- jsonlite::fromJSON(content)

  # Check for API error messages
  validate_api_response(parsed_data, ticker = "ETF")

  if ("Information" %in% names(parsed_data)) {
    stop("Alpha Vantage API Information: ", parsed_data$Information)
  }
  
  # Check if holdings data exists
  if (!"holdings" %in% names(parsed_data)) {
    stop("No holdings data found in API response")
  }
  
  holdings <- parsed_data$holdings
  
  # Check if holdings is empty
  if (length(holdings) == 0 || nrow(holdings) == 0) {
    stop("No holdings found for this ETF")
  }
  
  # Extract ticker symbols
  if (!"symbol" %in% names(holdings)) {
    stop("No symbol column found in holdings data")
  }
  
  tickers <- holdings$symbol
  
  # Remove any NA, empty values, or common invalid symbols
  tickers <- tickers[!is.na(tickers) & nchar(tickers) > 0]
  
  # Filter out common invalid ticker symbols
  invalid_patterns <- c("^n/a$", "^N/A$", "^-$", "^--$", "^NULL$", "^null$")
  for (pattern in invalid_patterns) {
    tickers <- tickers[!grepl(pattern, tickers, ignore.case = TRUE)]
  }
  
  if (length(tickers) == 0) {
    stop("No valid ticker symbols found in holdings")
  }
  
  # Return unique ticker symbols
  return(unique(tickers))
}
