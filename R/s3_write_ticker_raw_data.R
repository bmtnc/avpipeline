#' Write Single Ticker Raw Data to S3
#'
#' Uploads a single data type parquet file for a ticker to S3.
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

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  arrow::write_parquet(data, temp_file)

  s3_key <- generate_raw_data_s3_key(ticker, data_type)
  upload_artifact_to_s3(temp_file, bucket_name, s3_key, region)
}
