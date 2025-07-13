#' Parse Balance Sheet API Response
#'
#' Parses Alpha Vantage Balance Sheet API response into a standardized tibble format.
#' Only returns quarterly data to avoid mixing annual and quarterly numbers.
#'
#' @param response Raw httr response object from Alpha Vantage API
#' @param ticker Character. The equity ticker for metadata
#'
#' @return A tibble with quarterly balance sheet data
#' @keywords internal
#' @export
parse_balance_sheet_response <- function(response, ticker) {
  
  # Parse JSON response
  content <- httr::content(response, "text", encoding = "UTF-8")
  parsed_data <- jsonlite::fromJSON(content)
  
  # Check for API error messages
  if ("Error Message" %in% names(parsed_data)) {
    stop("Alpha Vantage API error: ", parsed_data$`Error Message`)
  }
  
  if ("Note" %in% names(parsed_data)) {
    stop("Alpha Vantage API note: ", parsed_data$Note)
  }
  
  # Extract quarterly reports only
  if (!"quarterlyReports" %in% names(parsed_data)) {
    stop("No quarterly reports found in API response for ticker: ", ticker)
  }
  
  quarterly_data <- parsed_data$quarterlyReports
  
  # Check if we have any quarterly data
  if (is.null(quarterly_data) || nrow(quarterly_data) == 0) {
    warning("No quarterly balance sheet data found for ticker: ", ticker)
    return(tibble::tibble())
  }
  
  # Convert to tibble and clean up
  result <- quarterly_data %>%
    tibble::as_tibble() %>%
    # Add ticker column
    dplyr::mutate(ticker = ticker, .before = 1) %>%
    # Convert fiscal date to proper date format
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding)) %>%
    # Convert "None" strings to NA across all columns
    dplyr::mutate(dplyr::across(dplyr::where(is.character), ~dplyr::na_if(.x, "None"))) %>%
    # Convert numeric columns (all financial data columns should be numeric)
    dplyr::mutate(dplyr::across(-c(ticker, fiscalDateEnding, reportedCurrency), ~as.numeric(.x))) %>%
    # Arrange by fiscal date (most recent first)
    dplyr::arrange(dplyr::desc(fiscalDateEnding))
  
  cat("Parsed", nrow(result), "quarterly balance sheet reports for", ticker, "\n")
  
  return(result)
}
