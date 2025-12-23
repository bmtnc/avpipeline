#' Read Checkpoint Artifact from S3
#'
#' Reads the intermediate artifact saved during checkpointing.
#'
#' @param bucket_name character: S3 bucket name
#' @param phase character: Phase name (e.g., "phase2")
#' @param region character: AWS region (default: "us-east-1")
#' @return tibble or empty tibble if no artifact exists
#' @keywords internal
s3_read_checkpoint_artifact <- function(bucket_name, phase, region = "us-east-1") {
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(phase, name = "phase")
  validate_character_scalar(region, name = "region")

  s3_key <- paste0("checkpoint/", phase, "_artifact.parquet")
  s3_uri <- paste0("s3://", bucket_name, "/", s3_key, "?region=", region)

  tryCatch({
    artifact <- arrow::read_parquet(s3_uri)
    log_pipeline(sprintf("Loaded checkpoint artifact: %d rows", nrow(artifact)))
    artifact
  }, error = function(e) {
    tibble::tibble()
  })
}


#' Write Checkpoint Artifact to S3
#'
#' Saves the intermediate artifact during checkpointing.
#'
#' @param artifact tibble: Current accumulated artifact
#' @param bucket_name character: S3 bucket name
#' @param phase character: Phase name (e.g., "phase2")
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if successful
#' @keywords internal
s3_write_checkpoint_artifact <- function(artifact, bucket_name, phase, region = "us-east-1") {
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(phase, name = "phase")
  validate_character_scalar(region, name = "region")

  if (nrow(artifact) == 0) {
    return(TRUE)
  }

  s3_key <- paste0("checkpoint/", phase, "_artifact.parquet")
  s3_uri <- paste0("s3://", bucket_name, "/", s3_key)

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  arrow::write_parquet(artifact, temp_file)

  result <- system2_with_timeout(
    "aws",
    args = c("s3", "cp", temp_file, s3_uri, "--region", region),
    timeout_seconds = 120,
    stdout = TRUE,
    stderr = TRUE
  )

  if (is_timeout_result(result)) {
    warning("Checkpoint artifact write timed out")
    return(FALSE)
  }

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    warning("Failed to write checkpoint artifact: ", paste(result, collapse = "\n"))
    return(FALSE)
  }

  TRUE
}


#' Clear Checkpoint Artifact from S3
#'
#' Removes the intermediate artifact after successful completion.
#'
#' @param bucket_name character: S3 bucket name
#' @param phase character: Phase name (e.g., "phase2")
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if successful
#' @keywords internal
s3_clear_checkpoint_artifact <- function(bucket_name, phase, region = "us-east-1") {
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(phase, name = "phase")
  validate_character_scalar(region, name = "region")

  s3_key <- paste0("checkpoint/", phase, "_artifact.parquet")
  s3_uri <- paste0("s3://", bucket_name, "/", s3_key)

  system2_with_timeout(
    "aws",
    args = c("s3", "rm", s3_uri, "--region", region),
    timeout_seconds = 30,
    stdout = TRUE,
    stderr = TRUE
  )

  TRUE
}
