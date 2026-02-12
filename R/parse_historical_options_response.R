#' Parse Historical Options Response to Tibble
#'
#' @param response httr2 response object
#' @param ticker Character. The equity ticker
#' @param datatype Character. Either "json" or "csv"
#'
#' @return A tibble with option chain data
#' @export
parse_historical_options_response <- function(response, ticker, datatype = "csv") {
  if (!datatype %in% c("json", "csv")) {
    stop("datatype must be 'json' or 'csv', got: ", datatype)
  }

  content <- httr2::resp_body_string(response)

  if (datatype == "json") {
    parsed_data <- jsonlite::fromJSON(content)
    validate_api_response(parsed_data, ticker = ticker)

    if (is.null(parsed_data$data) || length(parsed_data$data) == 0) {
      return(empty_options_tibble(ticker))
    }

    options_df <- tibble::as_tibble(parsed_data$data)

  } else if (datatype == "csv") {
    if (nchar(trimws(content)) == 0) {
      return(empty_options_tibble(ticker))
    }

    options_df <- read.csv(text = content, stringsAsFactors = FALSE)

    if (nrow(options_df) == 0) {
      return(empty_options_tibble(ticker))
    }

    options_df <- tibble::as_tibble(options_df)
  }

  # Standardize column name: symbol -> ticker
  if ("symbol" %in% names(options_df)) {
    options_df <- dplyr::rename(options_df, ticker = symbol)
  }
  if (!"ticker" %in% names(options_df)) {
    options_df$ticker <- ticker
  }

  # Type conversions
  options_df <- options_df %>%
    dplyr::mutate(
      date = as.Date(date),
      expiration = as.Date(expiration),
      strike = as.numeric(strike),
      last = as.numeric(last),
      mark = as.numeric(mark),
      bid = as.numeric(bid),
      bid_size = as.integer(bid_size),
      ask = as.numeric(ask),
      ask_size = as.integer(ask_size),
      volume = as.integer(volume),
      open_interest = as.integer(open_interest),
      implied_volatility = as.numeric(implied_volatility),
      delta = as.numeric(delta),
      gamma = as.numeric(gamma),
      theta = as.numeric(theta),
      vega = as.numeric(vega),
      rho = as.numeric(rho)
    ) %>%
    dplyr::select(
      ticker, contractID, date, expiration, strike, type,
      last, mark, bid, bid_size, ask, ask_size,
      volume, open_interest,
      implied_volatility, delta, gamma, theta, vega, rho
    ) %>%
    dplyr::arrange(expiration, strike, type)

  options_df
}

#' Create empty options tibble with correct column types
#'
#' @param ticker Character. The equity ticker
#' @return An empty tibble with the expected options schema
#' @keywords internal
empty_options_tibble <- function(ticker) {
  tibble::tibble(
    ticker = character(),
    contractID = character(),
    date = as.Date(character()),
    expiration = as.Date(character()),
    strike = numeric(),
    type = character(),
    last = numeric(),
    mark = numeric(),
    bid = numeric(),
    bid_size = integer(),
    ask = numeric(),
    ask_size = integer(),
    volume = integer(),
    open_interest = integer(),
    implied_volatility = numeric(),
    delta = numeric(),
    gamma = numeric(),
    theta = numeric(),
    vega = numeric(),
    rho = numeric()
  )
}
