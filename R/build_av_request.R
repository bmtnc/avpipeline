#' Build Alpha Vantage API Request
#'
#' Builds an httr2 request object without executing it.
#'
#' @param ticker character: Stock ticker symbol
#' @param api_function character: Alpha Vantage API function name
#' @param api_key character: API key
#' @param throttle_capacity numeric: Token bucket capacity (default: 1)
#' @param throttle_fill_time numeric: Seconds to refill one token (default: 1)
#' @param ... Additional query parameters (outputsize, datatype, etc.)
#' @return An unevaluated httr2_request object
#' @keywords internal
build_av_request <- function(ticker, api_function, api_key,
                             throttle_capacity = 1, throttle_fill_time = 1,
                             ...) {
  validate_character_scalar(ticker, name = "ticker")
  validate_character_scalar(api_function, name = "api_function")
  validate_character_scalar(api_key, name = "api_key")

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

  req <- httr2::request(base_url)

  for (param_name in names(query_params)) {
    req <- httr2::req_url_query(req, !!param_name := query_params[[param_name]])
  }

  req <- req %>%
    httr2::req_throttle(
      capacity = throttle_capacity,
      fill_time_s = throttle_fill_time,
      realm = "alphavantage"
    ) %>%
    httr2::req_timeout(seconds = 60) %>%
    httr2::req_retry(
      max_tries = 3,
      backoff = ~ 2
    )

  req
}
