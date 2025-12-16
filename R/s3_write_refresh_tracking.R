#' Write Refresh Tracking to S3
#'
#' Uploads the refresh tracking dataframe to S3.
#'
#' @param tracking tibble: Refresh tracking dataframe
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if upload successful
#' @keywords internal
s3_write_refresh_tracking <- function(tracking, bucket_name, region = "us-east-1") {
  if (!is.data.frame(tracking)) {
    stop("s3_write_refresh_tracking(): [tracking] must be a data.frame")
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("s3_write_refresh_tracking(): [bucket_name] must be a character scalar")
  }

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  arrow::write_parquet(tracking, temp_file)

  s3_key <- "raw/_metadata/refresh_tracking.parquet"
  upload_artifact_to_s3(temp_file, bucket_name, s3_key, region)
}
