#' Write Single Ticker Raw Data to S3
#'
#' Writes a parquet file directly to S3 using Arrow's native S3 filesystem.
#'
#' @param data data.frame: Data to upload
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data (e.g., "balance_sheet", "price")
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if upload successful
#' @keywords internal
s3_write_ticker_raw_data <- function(
  data,
  ticker,
  data_type,
  bucket_name,
  region = "us-east-1"
) {
  validate_df_type(data)
  validate_character_scalar(ticker, name = "ticker")
  validate_character_scalar(data_type, name = "data_type")
  validate_character_scalar(bucket_name, name = "bucket_name")

  s3_key <- generate_raw_data_s3_key(ticker, data_type)
  s3_uri <- paste0("s3://", bucket_name, "/", s3_key, "?region=", region)

  arrow::write_parquet(data, s3_uri)

  TRUE
}
