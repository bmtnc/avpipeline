#' Log Pipeline Message with Flush
#'
#' Logs a timestamped message and flushes output for CloudWatch visibility.
#'
#' @param ... Message parts (concatenated with no separator)
#' @param level Character. Log level: "INFO", "WARN", "ERROR" (default: "INFO")
#'
#' @return NULL (called for side effects)
#' @keywords internal
log_pipeline <- function(..., level = "INFO") {
  validate_character_scalar(level, name = "level")

  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  msg <- paste0("[", timestamp, "] [", level, "] ", paste0(..., collapse = ""))
  message(msg)
  flush.console()

  invisible(NULL)
}


#' Log Progress Summary
#'
#' Logs a formatted progress summary showing completion percentage and counts.
#'
#' @param current Integer. Current ticker index
#' @param total Integer. Total number of tickers
#' @param successful Integer. Count of successful tickers
#' @param failed Integer. Count of failed tickers
#' @param phase Character. Phase name for display (default: "Fetch")
#'
#' @return NULL (called for side effects)
#' @keywords internal
log_progress_summary <- function(current, total, successful, failed, phase = "Fetch") {
  pct <- round(100 * current / total, 1)
  log_pipeline(
    sprintf("[%d/%d] %s%% complete | %d successful | %d failed | Phase: %s",
            current, total, pct, successful, failed, phase),
    level = "INFO"
  )

  invisible(NULL)
}


#' Log Phase Start
#'
#' Logs the start of a pipeline phase.
#'
#' @param phase Character. Phase name
#' @param details Character. Additional details to log
#'
#' @return NULL (called for side effects)
#' @keywords internal
log_phase_start <- function(phase, details = "") {
  log_pipeline("=== ", phase, " STARTED ===")
  if (nchar(details) > 0) {
    log_pipeline(details)
  }

  invisible(NULL)
}


#' Log Phase End
#'
#' Logs the end of a pipeline phase with summary.
#'
#' @param phase Character. Phase name
#' @param total Integer. Total tickers processed
#' @param successful Integer. Successful count
#' @param failed Integer. Failed count
#' @param duration_seconds Numeric. Phase duration in seconds
#'
#' @return NULL (called for side effects)
#' @keywords internal
log_phase_end <- function(phase, total, successful, failed, duration_seconds) {
  log_pipeline("=== ", phase, " COMPLETE ===")
  log_pipeline(
    sprintf("Processed: %d | Success: %d | Failed: %d | Duration: %.1f min",
            total, successful, failed, duration_seconds / 60)
  )

  invisible(NULL)
}


#' Log Error
#'
#' Logs an error message with ticker context.
#'
#' @param ticker Character. Ticker symbol
#' @param error_msg Character. Error message
#'
#' @return NULL (called for side effects)
#' @keywords internal
log_error <- function(ticker, error_msg) {
  log_pipeline("ERROR [", ticker, "]: ", error_msg, level = "ERROR")

  invisible(NULL)
}
