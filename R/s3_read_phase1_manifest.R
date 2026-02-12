#' Read Phase 1 Manifest from S3
#'
#' Downloads the Phase 1 manifest listing tickers updated in the most recent Phase 1 run.
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return tibble or NULL: Manifest tibble, or NULL if not found
#' @keywords internal
s3_read_phase1_manifest <- function(bucket_name, region = "us-east-1") {

  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(region, name = "region")

  s3_uri <- sprintf(
    "s3://%s/raw/_metadata/phase1_manifest.parquet?region=%s",
    bucket_name, region
  )

  tryCatch(
    arrow::read_parquet(s3_uri),
    error = function(e) NULL
  )
}
