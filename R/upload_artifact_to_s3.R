#' Upload Artifact to S3
#'
#' Uploads a parquet file to S3 using AWS CLI.
#'
#' @param local_path character: Local file path to upload
#' @param bucket_name character: S3 bucket name
#' @param s3_key character: S3 key (path within bucket)
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if upload successful
#' @keywords internal
upload_artifact_to_s3 <- function(
  local_path,
  bucket_name,
  s3_key,
  region = "us-east-1"
) {
  validate_character_scalar(local_path, name = "local_path")
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(s3_key, name = "s3_key")
  validate_character_scalar(region, name = "region")
  validate_file_exists(local_path, name = "local_path")

  s3_uri <- paste0("s3://", bucket_name, "/", s3_key)

  message(paste0("Uploading ", local_path, " to ", s3_uri))

  result <- system2_with_timeout(
    "aws",
    args = c("s3", "cp", local_path, s3_uri, "--region", region),
    timeout_seconds = 60,
    stdout = TRUE,
    stderr = TRUE
  )

  if (is_timeout_result(result)) {
    stop("upload_artifact_to_s3(): S3 upload timed out after 60 seconds")
  }

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    stop(paste0(
      "upload_artifact_to_s3(): Failed to upload to S3. Error: ",
      paste(result, collapse = "\n")
    ))
  }

  message(paste0("Successfully uploaded to ", s3_uri))
  TRUE
}
