#' Parse Realtime Bulk Quotes Response to Tibble
#'
#' Parses a REALTIME_BULK_QUOTES JSON response into a tidy one-row-per-symbol
#' tibble of raw (unadjusted) current-day OHLCV plus the prior trading day's close.
#'
#' @param response httr2 response object from a REALTIME_BULK_QUOTES request
#' @return tibble with columns ticker, date, timestamp, open, high, low, close,
#'   volume, previous_close
#' @keywords internal
parse_bulk_quotes_response <- function(response) {
  content <- httr2::resp_body_string(response)
  data <- jsonlite::fromJSON(content)

  validate_api_response(data)
  if ("Information" %in% names(data)) {
    stop("Alpha Vantage API error: ", data$Information)
  }
  if (!"data" %in% names(data) || length(data$data) == 0) {
    stop("Unexpected REALTIME_BULK_QUOTES response: 'data' array not found or empty.")
  }

  tibble::as_tibble(data$data) %>%
    dplyr::transmute(
      ticker = symbol,
      date = as.Date(substr(timestamp, 1, 10)),
      timestamp = timestamp,
      open = as.numeric(open),
      high = as.numeric(high),
      low = as.numeric(low),
      close = as.numeric(close),
      volume = as.numeric(volume),
      previous_close = as.numeric(previous_close)
    )
}
