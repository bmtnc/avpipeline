#' Parse Company Overview API Response
#'
#' Parses Alpha Vantage OVERVIEW API response into a standardized tibble format.
#'
#' @param response Raw httr response object from Alpha Vantage API
#' @param ticker Character. The equity ticker for metadata
#'
#' @return A tibble with company metadata
#' @keywords internal
#' @export
parse_overview_response <- function(response, ticker) {
  content <- httr::content(response, "text", encoding = "UTF-8")
  parsed_data <- jsonlite::fromJSON(content)

  if ("Error Message" %in% names(parsed_data)) {
    stop("Alpha Vantage API error: ", parsed_data$`Error Message`)
  }

  if ("Note" %in% names(parsed_data)) {
    stop("Alpha Vantage API note: ", parsed_data$Note)
  }

  if (!"Symbol" %in% names(parsed_data)) {
    stop("No overview data found in API response for ticker: ", ticker)
  }

  result <- tibble::tibble(
    ticker = ticker,
    cik = parsed_data$CIK %||% NA_character_,
    exchange = parsed_data$Exchange %||% NA_character_,
    currency = parsed_data$Currency %||% NA_character_,
    country = parsed_data$Country %||% NA_character_,
    sector = parsed_data$Sector %||% NA_character_,
    industry = parsed_data$Industry %||% NA_character_,
    as_of_date = Sys.Date()
  )

  result <- dplyr::mutate(
    result,
    dplyr::across(dplyr::where(is.character), ~ dplyr::na_if(.x, "None"))
  )

  cat("Parsed overview data for", ticker, "\n")

  result
}
