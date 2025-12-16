#' Log Data Discrepancy to S3
#'
#' Writes mismatch details to the data changes log.
#'
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data (e.g., "balance_sheet")
#' @param mismatches data.frame: Mismatch details from validate_quarterly_consistency
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if logged successfully
#' @keywords internal
log_data_discrepancy <- function(ticker, data_type, mismatches, bucket_name, region = "us-east-1") {
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("log_data_discrepancy(): [ticker] must be a character scalar")
  }
  if (!is.character(data_type) || length(data_type) != 1) {
    stop("log_data_discrepancy(): [data_type] must be a character scalar")
  }
  if (!is.data.frame(mismatches)) {
    stop("log_data_discrepancy(): [mismatches] must be a data.frame")
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("log_data_discrepancy(): [bucket_name] must be a character scalar")
  }

  # Add metadata columns
  log_entry <- mismatches
  log_entry$logged_at <- Sys.time()
  log_entry$data_type <- data_type

  # Read existing log if it exists
  s3_key <- "raw/_metadata/data_changes_log.parquet"
  s3_uri <- paste0("s3://", bucket_name, "/", s3_key)

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  result <- system2("aws",
                    args = c("s3", "cp", s3_uri, temp_file, "--region", region),
                    stdout = TRUE,
                    stderr = TRUE)

  if (is.null(attr(result, "status")) || attr(result, "status") == 0) {
    if (file.exists(temp_file)) {
      existing_log <- arrow::read_parquet(temp_file)
      log_entry <- dplyr::bind_rows(existing_log, log_entry)
    }
  }

  # Write updated log
  arrow::write_parquet(log_entry, temp_file)
  upload_artifact_to_s3(temp_file, bucket_name, s3_key, region)

  TRUE
}
