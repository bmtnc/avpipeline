#' Parse Earnings Estimates API Response
#'
#' Parses Alpha Vantage EARNINGS_ESTIMATES API response into a standardized tibble.
#'
#' @param response httr2 response object from Alpha Vantage API
#' @param ticker Character. The equity ticker for metadata
#'
#' @return A tibble with earnings estimates data
#' @keywords internal
parse_earnings_estimates_response <- function(response, ticker) {

  content <- httr2::resp_body_string(response)
  parsed_data <- jsonlite::fromJSON(content)

  validate_api_response(parsed_data, ticker = ticker)

  if (!"estimates" %in% names(parsed_data)) {
    stop("No estimates found in API response for ticker: ", ticker)
  }

  estimates_data <- parsed_data$estimates

  if (is.null(estimates_data) || length(estimates_data) == 0) {
    warning("No earnings estimates data found for ticker: ", ticker)
    return(tibble::tibble())
  }

  numeric_cols <- get_earnings_estimates_metrics()

  result <- estimates_data %>%
    tibble::as_tibble() %>%
    dplyr::mutate(ticker = ticker, .before = 1) %>%
    dplyr::rename(fiscalDateEnding = date) %>%
    dplyr::mutate(fiscalDateEnding = as.Date(fiscalDateEnding)) %>%
    dplyr::mutate(dplyr::across(dplyr::where(is.character), ~dplyr::na_if(.x, "None"))) %>%
    dplyr::mutate(dplyr::across(dplyr::any_of(numeric_cols), as.numeric))

  # Ensure all expected columns exist (null API values may drop columns entirely)
  for (col in numeric_cols) {
    if (!col %in% names(result)) {
      result[[col]] <- NA_real_
    }
  }

  result <- result %>%
    dplyr::select(ticker, fiscalDateEnding, horizon, dplyr::all_of(numeric_cols)) %>%
    dplyr::arrange(dplyr::desc(fiscalDateEnding))

  result
}
