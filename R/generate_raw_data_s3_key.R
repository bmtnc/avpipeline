#' Generate S3 Key for Raw Ticker Data
#'
#' Generates the S3 key path for a specific ticker and data type.
#'
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data (e.g., "balance_sheet", "price")
#' @return character: S3 key path
#' @keywords internal
generate_raw_data_s3_key <- function(ticker, data_type) {
 if (!is.character(ticker) || length(ticker) != 1 || nchar(ticker) == 0) {

    stop("generate_raw_data_s3_key(): [ticker] must be a non-empty character scalar")
  }
  if (!is.character(data_type) || length(data_type) != 1 || nchar(data_type) == 0) {
    stop("generate_raw_data_s3_key(): [data_type] must be a non-empty character scalar")
  }

  paste0("raw/", ticker, "/", data_type, ".parquet")
}
