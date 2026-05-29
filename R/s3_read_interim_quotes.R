#' Read the Consolidated Interim Quotes File from S3
#'
#' Returns the accumulated provisional daily bars, or NULL when no interim file
#' exists (e.g. immediately after a weekly reconciliation). NULL lets callers
#' treat the overlay as a no-op.
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return tibble of interim quotes, or NULL if absent
#' @keywords internal
s3_read_interim_quotes <- function(bucket_name, region = "us-east-1") {
  validate_character_scalar(bucket_name, name = "bucket_name")

  s3_uri <- paste0(
    "s3://", bucket_name, "/interim/interim_quotes.parquet?region=", region
  )
  tryCatch(
    tibble::as_tibble(arrow::read_parquet(s3_uri)),
    error = function(e) NULL
  )
}
