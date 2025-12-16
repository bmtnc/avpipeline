#' Determine Missing Symbols
#'
#' Determines which symbols need to be fetched by comparing requested symbols
#' against symbols already present in cached data. Returns only the symbols
#' that are not already cached. Works with both 'ticker' and 'symbol' column names.
#'
#' @param requested_symbols Character vector of symbols requested
#' @param cached_data Data frame containing cached data with a 'ticker' or 'symbol' column
#' @param symbol_column Character. Name of the symbol column in cached_data.
#'   If NULL, will auto-detect 'ticker' or 'symbol' columns.
#' @return Character vector of symbols that need to be fetched
#' @export
determine_missing_symbols <- function(
  requested_symbols,
  cached_data,
  symbol_column = NULL
) {
  if (length(requested_symbols) == 0) {
    return(character(0))
  }
  # If no cached data, fetch all requested symbols
  if (is.null(cached_data) || nrow(cached_data) == 0) {
    return(requested_symbols)
  }
  # Auto-detect symbol column if not provided
  if (is.null(symbol_column)) {
    if ("ticker" %in% names(cached_data)) {
      symbol_column <- "ticker"
    } else if ("symbol" %in% names(cached_data)) {
      symbol_column <- "symbol"
    } else {
      stop("Cached data must contain either a 'ticker' or 'symbol' column")
    }
  }

  # Check if symbol column exists in cached data
  if (!symbol_column %in% names(cached_data)) {
    stop("Cached data must contain a '", symbol_column, "' column")
  }

  # Get distinct symbols from cached data
  cached_symbols <- cached_data %>%
    dplyr::distinct(!!dplyr::sym(symbol_column)) %>%
    dplyr::pull(!!dplyr::sym(symbol_column))

  # Return symbols that are not already cached
  symbols_to_fetch <- setdiff(requested_symbols, cached_symbols)

  return(symbols_to_fetch)
}
