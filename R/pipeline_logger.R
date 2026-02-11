#' Initialize Pipeline Log
#'
#' Creates an empty pipeline log dataframe.
#'
#' @return tibble: Empty log dataframe
#' @keywords internal
create_pipeline_log <- function() {

tibble::tibble(
    ticker = character(),
    phase = character(),
    data_type = character(),
    status = character(),
    rows = integer(),
    error_message = character(),
    duration_seconds = numeric(),
    timestamp = as.POSIXct(character())
  )
}

#' Add Entry to Pipeline Log
#'
#' Adds a single entry to the pipeline log.
#'
#' @param log tibble: Existing log dataframe
#' @param ticker character: Stock symbol
#' @param phase character: "fetch" or "generate"
#' @param data_type character: Type of data processed
#' @param status character: "success", "error", or "skipped"
#' @param rows integer: Number of rows processed (default: 0)
#' @param error_message character: Error message if any (default: NA)
#' @param duration_seconds numeric: Processing time (default: NA)
#' @return tibble: Updated log dataframe
#' @keywords internal
add_log_entry <- function(
log,
  ticker,
  phase,
  data_type,
  status,
  rows = 0L,
  error_message = NA_character_,
  duration_seconds = NA_real_
) {
  new_entry <- tibble::tibble(
    ticker = ticker,
    phase = phase,
    data_type = data_type,
    status = status,
    rows = as.integer(rows),
    error_message = error_message,
    duration_seconds = duration_seconds,
    timestamp = Sys.time()
  )

  dplyr::bind_rows(log, new_entry)
}

#' Upload Pipeline Log to S3
#'
#' Saves the pipeline log to S3.
#'
#' @param log tibble: Pipeline log dataframe
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if successful
#' @keywords internal
upload_pipeline_log <- function(log, bucket_name, region = "us-east-1") {
  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  arrow::write_parquet(log, temp_file)

  s3_key <- paste0("logs/", Sys.Date(), "/processing_log.parquet")
  upload_artifact_to_s3(temp_file, bucket_name, s3_key, region)

  TRUE
}
