#' Write the Consolidated Interim Quotes File to S3
#'
#' Writes a single parquet of provisional daily bars for all tickers to a fixed
#' key. One file per run keeps daily I/O at a single write rather than thousands
#' of per-ticker read-modify-writes.
#'
#' @param data data.frame: Normalized interim quotes (price artifact schema)
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if upload successful
#' @keywords internal
s3_write_interim_quotes <- function(data, bucket_name, region = "us-east-1") {
  validate_df_type(data)
  validate_character_scalar(bucket_name, name = "bucket_name")

  s3_uri <- paste0(
    "s3://",
    bucket_name,
    "/interim/interim_quotes.parquet?region=",
    region
  )
  arrow::write_parquet(data, s3_uri)

  TRUE
}
