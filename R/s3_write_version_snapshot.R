#' Write Version Snapshot to S3
#'
#' Creates a timestamped backup of existing data before overwriting.
#'
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if snapshot created, FALSE if no existing data
#' @keywords internal
s3_write_version_snapshot <- function(
  ticker,
  data_type,
  bucket_name,
  region = "us-east-1"
) {
  validate_character_scalar(ticker, name = "ticker")
  validate_character_scalar(data_type, name = "data_type")
  validate_character_scalar(bucket_name, name = "bucket_name")

  existing_data <- s3_read_ticker_raw_data_single(
    ticker,
    data_type,
    bucket_name,
    region
  )

  if (is.null(existing_data)) {
    return(FALSE)
  }

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  arrow::write_parquet(existing_data, temp_file)

  version_key <- generate_version_snapshot_s3_key(ticker, data_type, Sys.Date())
  upload_artifact_to_s3(temp_file, bucket_name, version_key, region)

  TRUE
}
