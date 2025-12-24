#' Load TTM Quarterly Artifact from S3
#'
#' Downloads and loads the quarterly TTM artifact from S3.
#'
#' @param bucket_name character: S3 bucket name
#' @param artifact_date Date: Date of the artifact (default: latest)
#' @param region character: AWS region (default: "us-east-1")
#' @return tibble: Quarterly TTM financial data
#' @export
load_quarterly_artifact <- function(
    bucket_name,
    artifact_date = NULL,
    region = "us-east-1"
) {
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(region, name = "region")

  if (is.null(artifact_date)) {
    artifact_date <- find_latest_artifact_date(bucket_name, region)
  }

  date_string <- format(artifact_date, "%Y-%m-%d")
  s3_uri <- sprintf(
    "s3://%s/ttm-artifacts/%s/ttm_quarterly_artifact.parquet?region=%s",
    bucket_name, date_string, region
  )

  arrow::read_parquet(s3_uri)
}


#' Load Price Artifact from S3
#'
#' Downloads and loads the price artifact from S3.
#'
#' @param bucket_name character: S3 bucket name
#' @param artifact_date Date: Date of the artifact (default: latest)
#' @param region character: AWS region (default: "us-east-1")
#' @return tibble: Daily price data
#' @export
load_price_artifact <- function(
    bucket_name,
    artifact_date = NULL,
    region = "us-east-1"
) {
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(region, name = "region")

  if (is.null(artifact_date)) {
    artifact_date <- find_latest_artifact_date(bucket_name, region)
  }

  date_string <- format(artifact_date, "%Y-%m-%d")
  s3_uri <- sprintf(
    "s3://%s/ttm-artifacts/%s/price_artifact.parquet?region=%s",
    bucket_name, date_string, region
  )

  arrow::read_parquet(s3_uri)
}


#' Find Latest Artifact Date
#'
#' Finds the most recent artifact date in S3.
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region
#' @return Date: Most recent artifact date
#' @keywords internal
find_latest_artifact_date <- function(bucket_name, region) {
  # List objects in ttm-artifacts prefix
  result <- system2(
    "aws",
    args = c(
      "s3", "ls",
      sprintf("s3://%s/ttm-artifacts/", bucket_name),
      "--region", region
    ),
    stdout = TRUE,
    stderr = FALSE
  )

  # Parse directory names (format: PRE YYYY-MM-DD/)
  dates <- gsub(".*PRE\\s+", "", result)
  dates <- gsub("/.*", "", dates)
  dates <- dates[grepl("^\\d{4}-\\d{2}-\\d{2}$", dates)]

  if (length(dates) == 0) {
    stop("No artifacts found in s3://", bucket_name, "/ttm-artifacts/")
  }

  max(as.Date(dates))
}


#' Load and Create Daily TTM Artifact from S3
#'
#' Convenience function that loads both artifacts from S3 and creates the
#' daily TTM artifact in one call.
#'
#' @param bucket_name character: S3 bucket name
#' @param artifact_date Date: Date of the artifacts (default: latest)
#' @param tickers character: Optional vector of tickers to filter to
#' @param start_date Date: Optional start date for filtering
#' @param region character: AWS region (default: "us-east-1")
#' @return tibble: Daily-frequency TTM per-share artifact
#' @export
load_daily_ttm_artifact <- function(
    bucket_name,
    artifact_date = NULL,
    tickers = NULL,
    start_date = NULL,
    region = "us-east-1"
) {
  # Load both artifacts
  quarterly_df <- load_quarterly_artifact(bucket_name, artifact_date, region)
  price_df <- load_price_artifact(bucket_name, artifact_date, region)

  # Create daily artifact on-demand

  create_daily_ttm_artifact(
    quarterly_df = quarterly_df,
    price_df = price_df,
    tickers = tickers,
    start_date = start_date
  )
}
