#' Clear the Consolidated Interim Quotes File from S3
#'
#' Removes the interim quotes file. Called once the authoritative history has
#' fully superseded every interim bar (i.e. the weekly reconciliation has caught
#' up), since stale interim rows are otherwise ignored but accumulate.
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE (whether or not the file existed)
#' @keywords internal
s3_clear_interim_quotes <- function(bucket_name, region = "us-east-1") {
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(region, name = "region")

  s3_uri <- paste0("s3://", bucket_name, "/interim/interim_quotes.parquet")

  system2_with_timeout(
    "aws",
    args = c("s3", "rm", s3_uri, "--region", region),
    timeout_seconds = 30,
    stdout = TRUE,
    stderr = TRUE
  )

  TRUE
}
