#' Parse Earnings API Response
#'
#' Parses Alpha Vantage Earnings API response into a standardized tibble format.
#' Focuses on quarterly earnings data to provide timing metadata for financial statements.
#'
#' @param response httr2 response object from Alpha Vantage API
#' @param ticker Character. The equity ticker for metadata
#'
#' @return A tibble with quarterly earnings timing data
#' @keywords internal
#' @export
parse_earnings_response <- function(response, ticker) {
  
  # Parse JSON response
  content <- httr2::resp_body_string(response)
  parsed_data <- jsonlite::fromJSON(content)

  # Check for API error messages
  validate_api_response(parsed_data, ticker = ticker)
  
  # Extract quarterly earnings data
  if (!"quarterlyEarnings" %in% names(parsed_data)) {
    stop("No quarterly earnings found in API response for ticker: ", ticker)
  }
  
  quarterly_data <- parsed_data$quarterlyEarnings
  
  # Check if we have any quarterly data
  if (is.null(quarterly_data) || nrow(quarterly_data) == 0) {
    warning("No quarterly earnings data found for ticker: ", ticker)
    return(tibble::tibble())
  }
  
  # Convert to tibble and focus on key timing fields
  result <- quarterly_data %>%
    tibble::as_tibble() %>%
    # Add ticker column
    dplyr::mutate(ticker = ticker, .before = 1) %>%
    # Convert date columns to proper date format
    dplyr::mutate(
      fiscalDateEnding = as.Date(fiscalDateEnding),
      reportedDate = as.Date(reportedDate)
    ) %>%
    # Select key fields for joining with financial statements
    dplyr::select(
      ticker,
      fiscalDateEnding,
      reportedDate,
      reportTime
    ) %>%
    # Convert "None" strings to NA
    dplyr::mutate(dplyr::across(dplyr::where(is.character), ~dplyr::na_if(.x, "None"))) %>%
    # Arrange by fiscal date (most recent first)
    dplyr::arrange(dplyr::desc(fiscalDateEnding))

  return(result)
}
