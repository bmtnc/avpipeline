#' Validate Alpha Vantage API Response
#'
#' Validates that an API response does not contain error messages or rate limit notes.
#' This function should be called after parsing the JSON response.
#'
#' @param parsed_data Named list from jsonlite::fromJSON()
#' @param ticker Character scalar ticker symbol (for error messages)
#'
#' @return NULL (called for side effects)
#' @keywords internal
validate_api_response <- function(parsed_data, ticker = "unknown") {
  if ("Error Message" %in% names(parsed_data)) {
    stop("Alpha Vantage API error: ", parsed_data$`Error Message`)
  }
  if ("Note" %in% names(parsed_data)) {
    stop("Alpha Vantage API rate limit: ", parsed_data$Note)
  }
}
