#' Read Refresh Tracking from S3
#'
#' Downloads the refresh tracking dataframe from S3. Returns empty tracking if not found.
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

  result <- system2("aws",
                    args = c("s3", "cp", s3_uri, temp_file, "--region", region),
                    stdout = TRUE,
                    stderr = TRUE)

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    message("No existing refresh tracking found, creating empty tracking")
    return(create_empty_refresh_tracking())
  }

  if (!file.exists(temp_file)) {
    return(create_empty_refresh_tracking())
  }

  arrow::read_parquet(temp_file)
}
