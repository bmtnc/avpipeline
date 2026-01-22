#' Get Config for Data Type
#'
#' Maps a data type name to its corresponding configuration object.
#'
#' @param data_type character: Type of data (e.g., "balance_sheet", "price")
#' @return list: Configuration object, or NULL if unknown data_type
#' @keywords internal
get_config_for_data_type <- function(data_type) {
  if (!is.character(data_type) || length(data_type) != 1) {
    stop("get_config_for_data_type(): [data_type] must be a character scalar")
  }

  config_map <- list(
    price = PRICE_CONFIG,
    splits = SPLITS_CONFIG,
    balance_sheet = BALANCE_SHEET_CONFIG,
    income_statement = INCOME_STATEMENT_CONFIG,
    cash_flow = CASH_FLOW_CONFIG,
    earnings = EARNINGS_CONFIG
  )

  config_map[[data_type]]
}
