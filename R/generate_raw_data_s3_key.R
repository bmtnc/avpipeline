#' Generate S3 Key for Raw Ticker Data
#'
#' Generates the S3 key path for a specific ticker and data type.
#'
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data (e.g., "balance_sheet", "price")
#' @return character: S3 key path
#' @keywords internal
generate_raw_data_s3_key <- function(ticker, data_type) {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")
  validate_character_scalar(data_type, allow_empty = FALSE, name = "data_type")

  paste0("raw/", ticker, "/", data_type, ".parquet")
}
