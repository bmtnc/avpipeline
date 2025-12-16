#' Generate S3 Artifact Key
#'
#' Generates a date-based S3 key path for storing TTM artifact files.
#'
#' @param date Date: The date for the artifact (defaults to current date)
#' @return character: S3 key path in format "ttm-artifacts/YYYY-MM-DD/ttm_per_share_financial_artifact.parquet"
#' @keywords internal
generate_s3_artifact_key <- function(date = Sys.Date()) {
  validate_date_type(date, scalar = TRUE, name = "date")

  date_string <- format(date, "%Y-%m-%d")
  paste0(
    "ttm-artifacts/",
    date_string,
    "/ttm_per_share_financial_artifact.parquet"
  )
}
