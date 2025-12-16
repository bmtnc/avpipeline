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
  if (!is.character(local_path) || length(local_path) != 1) {
    stop(paste0(
      "upload_artifact_to_s3(): [local_path] must be a character scalar, not ",
      class(local_path)[1],
      " of length ",
      length(local_path)
    ))
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop(paste0(
      "upload_artifact_to_s3(): [bucket_name] must be a character scalar, not ",
      class(bucket_name)[1],
      " of length ",
      length(bucket_name)
    ))
  }
  if (!is.character(s3_key) || length(s3_key) != 1) {
    stop(paste0(
      "upload_artifact_to_s3(): [s3_key] must be a character scalar, not ",
      class(s3_key)[1],
      " of length ",
      length(s3_key)
    ))
  }
  if (!is.character(region) || length(region) != 1) {
    stop(paste0(
      "upload_artifact_to_s3(): [region] must be a character scalar, not ",
      class(region)[1],
      " of length ",
      length(region)
    ))
  }
  if (!file.exists(local_path)) {
    stop(paste0(
      "upload_artifact_to_s3(): [local_path] file does not exist: ",
      local_path
    ))
  }

  s3_uri <- paste0("s3://", bucket_name, "/", s3_key)

  message(paste0("Uploading ", local_path, " to ", s3_uri))

  result <- system2(
    "aws",
    args = c("s3", "cp", local_path, s3_uri, "--region", region),
    stdout = TRUE,
    stderr = TRUE
  )

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    stop(paste0(
      "upload_artifact_to_s3(): Failed to upload to S3. Error: ",
      paste(result, collapse = "\n")
    ))
  }

  message(paste0("Successfully uploaded to ", s3_uri))
  TRUE
}
