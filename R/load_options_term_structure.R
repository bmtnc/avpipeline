#' Load Raw Options Term Structure Artifact from S3
#'
#' @param bucket_name character: S3 bucket name
#' @param artifact_date Date: Date of the artifact (default: latest)
#' @param region character: AWS region (default: "us-east-1")
#' @return tibble: Raw IV term structure data
#' @export
load_options_raw_term_structure <- function(
    bucket_name,
    artifact_date = NULL,
    region = "us-east-1"
) {
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(region, name = "region")

  if (is.null(artifact_date)) {
    artifact_date <- find_latest_options_artifact_date(bucket_name, region)
  }

  date_string <- format(artifact_date, "%Y-%m-%d")
  s3_uri <- sprintf(
    "s3://%s/options-artifacts/%s/raw_term_structure.parquet?region=%s",
    bucket_name, date_string, region
  )

  arrow::read_parquet(s3_uri)
}


#' Load Interpolated Options Term Structure Artifact from S3
#'
#' @param bucket_name character: S3 bucket name
#' @param artifact_date Date: Date of the artifact (default: latest)
#' @param region character: AWS region (default: "us-east-1")
#' @return tibble: Interpolated IV term structure data at standard tenors
#' @export
load_options_interpolated_term_structure <- function(
    bucket_name,
    artifact_date = NULL,
    region = "us-east-1"
) {
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(region, name = "region")

  if (is.null(artifact_date)) {
    artifact_date <- find_latest_options_artifact_date(bucket_name, region)
  }

  date_string <- format(artifact_date, "%Y-%m-%d")
  s3_uri <- sprintf(
    "s3://%s/options-artifacts/%s/interpolated_term_structure.parquet?region=%s",
    bucket_name, date_string, region
  )

  arrow::read_parquet(s3_uri)
}


#' Find Latest Options Artifact Date in S3
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region
#' @return Date: Most recent options artifact date
#' @keywords internal
find_latest_options_artifact_date <- function(bucket_name, region) {
  result <- system2(
    "aws",
    args = c(
      "s3", "ls",
      sprintf("s3://%s/options-artifacts/", bucket_name),
      "--region", region
    ),
    stdout = TRUE,
    stderr = FALSE
  )

  dates <- gsub(".*PRE\\s+", "", result)
  dates <- gsub("/.*", "", dates)
  dates <- dates[grepl("^\\d{4}-\\d{2}-\\d{2}$", dates)]

  if (length(dates) == 0) {
    stop("No options artifacts found in s3://", bucket_name, "/options-artifacts/")
  }

  max(as.Date(dates))
}
