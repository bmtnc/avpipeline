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

#' Print Progress Bar
#'
#' Prints a simple progress indicator.
#'
#' @param current integer: Current item number
#' @param total integer: Total items
#' @param phase character: Phase name
#' @param ticker character: Current ticker (optional)
#' @keywords internal
print_progress <- function(current, total, phase, ticker = NULL) {
  pct <- current / total
  bar_width <- 30
  filled <- round(pct * bar_width)
  empty <- bar_width - filled

  bar <- paste0(
    "[",
    paste(rep("=", filled), collapse = ""),
    if (filled < bar_width) ">" else "",
    paste(rep(" ", max(0, empty - 1)), collapse = ""),
    "]"
  )

  ticker_str <- if (!is.null(ticker)) paste0(" ", ticker) else ""

  cat(sprintf("\r%s %s %d/%d%s", phase, bar, current, total, ticker_str))

  if (current == total) cat("\n")
}

#' Print Log Summary
#'
#' Prints a summary of the pipeline log.
#'
#' @param log tibble: Pipeline log dataframe
#' @param phase character: Phase to summarize (optional, summarizes all if NULL)
#' @keywords internal
print_log_summary <- function(log, phase = NULL) {
  if (!is.null(phase)) {
    log <- dplyr::filter(log, phase == !!phase)
  }

  summary <- log %>%
    dplyr::group_by(phase, status) %>%
    dplyr::summarise(
      count = dplyr::n_distinct(ticker),
      total_rows = sum(rows, na.rm = TRUE),
      .groups = "drop"
    )

  for (p in unique(summary$phase)) {
    phase_summary <- dplyr::filter(summary, phase == p)
    success_count <- phase_summary$count[phase_summary$status == "success"]
    if (length(success_count) == 0) success_count <- 0
    error_count <- phase_summary$count[phase_summary$status == "error"]
    if (length(error_count) == 0) error_count <- 0
    skipped_count <- phase_summary$count[phase_summary$status == "skipped"]
    if (length(skipped_count) == 0) skipped_count <- 0

    total_rows <- sum(phase_summary$total_rows)

    cat(sprintf(
      "  %s: %d success, %d errors, %d skipped (%d rows)\n",
      tools::toTitleCase(p), success_count, error_count, skipped_count, total_rows
    ))
  }

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
