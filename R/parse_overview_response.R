#' Parse Alpha Vantage Overview Response
#'
#' Parses the JSON response from Alpha Vantage's OVERVIEW endpoint into a
#' one-row tibble of company metadata. Values are kept verbatim (UPPERCASE
#' sector/industry as returned by Alpha Vantage). An empty or symbol-less
#' response (invalid ticker) yields a zero-row tibble with the same structure.
#'
#' @param response httr2 response object from Alpha Vantage API
#' @param ticker character: Stock ticker symbol
#' @return tibble with columns: ticker, cik, exchange, currency, country, sector, industry, as_of_date
#' @keywords internal
parse_overview_response <- function(response, ticker) {
  content <- httr2::resp_body_string(response)
  response_content <- jsonlite::fromJSON(content)

  if (!is.list(response_content)) {
    stop(
      "API returned non-JSON response for ticker ",
      ticker,
      ". Response: ",
      substr(as.character(response_content), 1, 200)
    )
  }

  validate_api_response(response_content, ticker = ticker)

  empty_overview <- tibble::tibble(
    ticker = character(0),
    cik = character(0),
    exchange = character(0),
    currency = character(0),
    country = character(0),
    sector = character(0),
    industry = character(0),
    as_of_date = as.Date(character(0))
  )

  # Invalid/unknown symbols return an empty object {} (no Symbol field)
  if (is.null(response_content$Symbol)) {
    return(empty_overview)
  }

  field <- function(name) {
    value <- response_content[[name]]
    if (is.null(value) || length(value) == 0) {
      NA_character_
    } else {
      as.character(value)
    }
  }

  tibble::tibble(
    ticker = ticker,
    cik = field("CIK"),
    exchange = field("Exchange"),
    currency = field("Currency"),
    country = field("Country"),
    sector = field("Sector"),
    industry = field("Industry"),
    as_of_date = Sys.Date()
  )
}
