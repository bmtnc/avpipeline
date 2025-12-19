#' Read Refresh Tracking from S3
#'
#' Downloads the refresh tracking dataframe from S3. If tracking doesn't exist
#' but raw data does, initializes tracking from existing data.
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return tibble: Refresh tracking dataframe
#' @keywords internal
s3_read_refresh_tracking <- function(bucket_name, region = "us-east-1") {
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("s3_read_refresh_tracking(): [bucket_name] must be a character scalar")
  }

  s3_key <- "raw/_metadata/refresh_tracking.parquet"
  s3_uri <- paste0("s3://", bucket_name, "/", s3_key)

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  result <- system2_with_timeout(
    "aws",
    args = c("s3", "cp", s3_uri, temp_file, "--region", region),
    timeout_seconds = 30,
    stdout = TRUE,
    stderr = TRUE
  )

  if (is_timeout_result(result) ||
      (!is.null(attr(result, "status")) && attr(result, "status") != 0)) {
    return(initialize_tracking_from_s3_data(bucket_name, region))
  }

  if (!file.exists(temp_file)) {
    return(initialize_tracking_from_s3_data(bucket_name, region))
  }

  tracking <- arrow::read_parquet(temp_file)

  tracking <- migrate_tracking_schema(tracking)

  tracking
}
