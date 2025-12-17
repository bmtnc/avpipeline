#' Read Checkpoint from S3
#'
#' Reads the checkpoint file for a pipeline phase from S3.
#'
#' @param bucket_name Character. S3 bucket name
#' @param phase Character. Phase name (e.g., "phase1", "phase2")
#' @param region Character. AWS region (default: "us-east-1")
#'
#' @return List with processed_tickers, failed_tickers, run_id, last_updated.
#'   Returns empty checkpoint if none exists.
#' @keywords internal
s3_read_checkpoint <- function(bucket_name, phase, region = "us-east-1") {
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(phase, name = "phase")
  validate_character_scalar(region, name = "region")

  s3_key <- paste0("checkpoint/", phase, "_checkpoint.json")
  s3_uri <- paste0("s3://", bucket_name, "/", s3_key)

  temp_file <- tempfile(fileext = ".json")
  on.exit(unlink(temp_file), add = TRUE)

  result <- system2_with_timeout(
    "aws",
    args = c("s3", "cp", s3_uri, temp_file, "--region", region),
    timeout_seconds = 30,
    stdout = TRUE,
    stderr = TRUE
  )

  if (is_timeout_result(result) ||
      (!is.null(attr(result, "status")) && attr(result, "status") != 0)) {
    return(create_empty_checkpoint())
  }

  if (!file.exists(temp_file)) {
    return(create_empty_checkpoint())
  }

  tryCatch({
    checkpoint <- jsonlite::fromJSON(temp_file, simplifyVector = TRUE)
    checkpoint$processed_tickers <- as.character(checkpoint$processed_tickers %||% character(0))
    checkpoint$failed_tickers <- as.character(checkpoint$failed_tickers %||% character(0))
    checkpoint
  }, error = function(e) {
    warning("Failed to parse checkpoint file: ", e$message)
    create_empty_checkpoint()
  })
}


#' Write Checkpoint to S3
#'
#' Writes the checkpoint file for a pipeline phase to S3.
#'
#' @param checkpoint List. Checkpoint data with processed_tickers, failed_tickers
#' @param bucket_name Character. S3 bucket name
#' @param phase Character. Phase name (e.g., "phase1", "phase2")
#' @param region Character. AWS region (default: "us-east-1")
#'
#' @return Logical. TRUE if successful
#' @keywords internal
s3_write_checkpoint <- function(checkpoint, bucket_name, phase, region = "us-east-1") {
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(phase, name = "phase")
  validate_character_scalar(region, name = "region")

  checkpoint$last_updated <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")

  temp_file <- tempfile(fileext = ".json")
  on.exit(unlink(temp_file), add = TRUE)

  jsonlite::write_json(checkpoint, temp_file, auto_unbox = TRUE, pretty = TRUE)

  s3_key <- paste0("checkpoint/", phase, "_checkpoint.json")
  s3_uri <- paste0("s3://", bucket_name, "/", s3_key)

  result <- system2_with_timeout(
    "aws",
    args = c("s3", "cp", temp_file, s3_uri, "--region", region),
    timeout_seconds = 30,
    stdout = TRUE,
    stderr = TRUE
  )

  if (is_timeout_result(result)) {
    warning("Checkpoint write timed out after 30 seconds")
    return(FALSE)
  }

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    warning("Failed to write checkpoint to S3: ", paste(result, collapse = "\n"))
    return(FALSE)
  }

  TRUE
}


#' Clear Checkpoint from S3
#'
#' Removes the checkpoint file for a pipeline phase from S3.
#' Called after successful completion to prevent stale checkpoints.
#'
#' @param bucket_name Character. S3 bucket name
#' @param phase Character. Phase name (e.g., "phase1", "phase2")
#' @param region Character. AWS region (default: "us-east-1")
#'
#' @return Logical. TRUE if successful (or file didn't exist)
#' @keywords internal
s3_clear_checkpoint <- function(bucket_name, phase, region = "us-east-1") {
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(phase, name = "phase")
  validate_character_scalar(region, name = "region")

  s3_key <- paste0("checkpoint/", phase, "_checkpoint.json")
  s3_uri <- paste0("s3://", bucket_name, "/", s3_key)

  result <- system2_with_timeout(
    "aws",
    args = c("s3", "rm", s3_uri, "--region", region),
    timeout_seconds = 30,
    stdout = TRUE,
    stderr = TRUE
  )

  TRUE
}


#' Create Empty Checkpoint
#'
#' Creates an empty checkpoint structure.
#'
#' @return List with empty processed_tickers and failed_tickers
#' @keywords internal
create_empty_checkpoint <- function() {
  list(
    run_id = paste0("run_", format(Sys.time(), "%Y%m%d_%H%M%S")),
    processed_tickers = character(0),
    failed_tickers = character(0),
    last_updated = NULL
  )
}


#' Update Checkpoint with Processed Ticker
#'
#' Adds a ticker to the processed or failed list in the checkpoint.
#'
#' @param checkpoint List. Current checkpoint
#' @param ticker Character. Ticker symbol
#' @param success Logical. TRUE if ticker was processed successfully
#'
#' @return Updated checkpoint list
#' @keywords internal
update_checkpoint <- function(checkpoint, ticker, success = TRUE) {
  if (success) {
    checkpoint$processed_tickers <- unique(c(checkpoint$processed_tickers, ticker))
  } else {
    checkpoint$failed_tickers <- unique(c(checkpoint$failed_tickers, ticker))
  }
  checkpoint
}
