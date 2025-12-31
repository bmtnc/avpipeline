#' Get Latest TTM Artifact from S3
#'
#' Convenience function to load the most recent TTM quarterly artifact.
#'
#' @param bucket_name character: S3 bucket name (default: "avpipeline-artifacts-prod")
#' @param region character: AWS region (default: "us-east-1")
#' @return tibble: Quarterly TTM financial data
#' @export
get_latest_ttm_artifact <- function(
  bucket_name = "avpipeline-artifacts-prod",
  region = "us-east-1"
) {
  load_quarterly_artifact(
    bucket_name = bucket_name,
    artifact_date = NULL,
    region = region
  )
}
