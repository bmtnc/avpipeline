#' Write Refresh Tracking to S3
#'
#' Uploads the refresh tracking dataframe to S3.
#'
#' @param tracking tibble: Refresh tracking dataframe
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if upload successful
#' @keywords internal
s3_write_refresh_tracking <- function(
  tracking,
  bucket_name,
  region = "us-east-1"
) {
  validate_df_type(tracking)
  validate_character_scalar(bucket_name, name = "bucket_name")

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  arrow::write_parquet(tracking, temp_file)

  s3_key <- "raw/_metadata/refresh_tracking.parquet"
  upload_artifact_to_s3(temp_file, bucket_name, s3_key, region)
}
