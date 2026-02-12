#' Write Phase 1 Manifest to S3
#'
#' Derives a manifest of updated tickers from the pipeline log and writes to S3.
#'
#' @param pipeline_log tibble: Pipeline log from Phase 1
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return invisible(TRUE) if successful
#' @keywords internal
s3_write_phase1_manifest <- function(pipeline_log, bucket_name, region = "us-east-1") {

  validate_df_type(pipeline_log)
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(region, name = "region")

  manifest <- derive_phase1_manifest(pipeline_log)

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  arrow::write_parquet(manifest, temp_file)

  s3_key <- "raw/_metadata/phase1_manifest.parquet"
  upload_artifact_to_s3(temp_file, bucket_name, s3_key, region)

  invisible(TRUE)
}
