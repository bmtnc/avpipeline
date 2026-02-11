#' Make Alpha Vantage API Request
#'
#' Makes HTTP requests to the Alpha Vantage API with retry logic.
#'
#' @param ticker character: Stock ticker symbol
#' @param api_function character: Alpha Vantage API function name
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @param ... Additional query parameters (outputsize, datatype, etc.)
#' @return Raw httr response object
#' @keywords internal
make_av_request <- function(ticker, api_function, api_key = NULL, ...) {
  validate_character_scalar(ticker, name = "ticker")
  validate_character_scalar(api_function, name = "api_function")

  if (is.null(api_key)) {
    api_key <- get_api_key()
  }

  base_url <- "https://www.alphavantage.co/query"

  query_params <- list(
    `function` = api_function,
    symbol = ticker,
    apikey = api_key
  )

  additional_params <- list(...)
  if (length(additional_params) > 0) {
    query_params <- c(query_params, additional_params)
  }

  response <- with_retry(
    {
      resp <- httr::GET(
        url = base_url,
        query = query_params,
        httr::timeout(60)
      )

      if (httr::status_code(resp) != 200) {
        stop("API request failed with status code: ", httr::status_code(resp))
      }

      resp
    },
    max_attempts = 3,
    initial_delay = 5,
    backoff_multiplier = 2,
    retryable_errors = "rate limit|timeout|connection|timed out|429"
  )

  response
}
