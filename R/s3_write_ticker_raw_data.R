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
  if (!is.data.frame(data)) {
    stop("s3_write_ticker_raw_data(): [data] must be a data.frame")
  }
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("s3_write_ticker_raw_data(): [ticker] must be a character scalar")
  }
  if (!is.character(data_type) || length(data_type) != 1) {
    stop("s3_write_ticker_raw_data(): [data_type] must be a character scalar")
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("s3_write_ticker_raw_data(): [bucket_name] must be a character scalar")
  }

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  arrow::write_parquet(data, temp_file)

  s3_key <- generate_raw_data_s3_key(ticker, data_type)
  upload_artifact_to_s3(temp_file, bucket_name, s3_key, region)
}
