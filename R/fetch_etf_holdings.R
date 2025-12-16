#' Fetch ETF holdings ticker symbols from Alpha Vantage
#'
#' This function retrieves the holdings/constituents of an ETF from Alpha Vantage
#' and returns a character vector of ticker symbols that can be used with other
#' price fetching functions.
#'
#' @param etf_symbol Character. The ETF symbol (e.g., "QQQ", "SPY")
#' @param api_key Character. Alpha Vantage API key. If NULL, will use get_api_key()
#'
#' @return Character vector of ticker symbols from the ETF holdings
#' @export
#'
fetch_etf_holdings <- function(etf_symbol, api_key = NULL) {
  validate_character_scalar(etf_symbol, allow_empty = FALSE, name = "etf_symbol")

  # Convert to uppercase for consistency
  etf_symbol <- toupper(etf_symbol)

  # Make API request using configuration-based approach
  response <- make_alpha_vantage_request(
    etf_symbol,
    ETF_PROFILE_CONFIG,
    api_key
  )

  # Parse response and extract ticker symbols
  tickers <- parse_etf_profile_response(response)

  cat(
    "Successfully fetched",
    length(tickers),
    "holdings for ETF:",
    etf_symbol,
    "\n"
  )

  return(tickers)
}
