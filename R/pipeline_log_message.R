#' Get Pipeline Execution ID
#'
#' Returns the execution ID for log correlation. Uses EXECUTION_ID env var
#' if set, otherwise generates one from the current timestamp.
#'
#' @return Character. Execution ID for this pipeline run
#' @keywords internal
get_execution_id <- function() {

  exec_id <- Sys.getenv("EXECUTION_ID", "")
  if (exec_id == "") {
    exec_id <- format(Sys.time(), "%Y%m%d-%H%M%S")
    Sys.setenv(EXECUTION_ID = exec_id)
  }
  exec_id
}


#' Log Pipeline Message with Flush
#'
#' Logs a timestamped message with execution ID and flushes output for
#' CloudWatch visibility.
#'
#' @param ... Message parts (concatenated with no separator)
#' @param level Character. Log level: "INFO", "WARN", "ERROR" (default: "INFO")
#'
#' @return NULL (called for side effects)
#' @keywords internal
log_pipeline <- function(..., level = "INFO") {
  validate_character_scalar(level, name = "level")

  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  exec_id <- get_execution_id()
  msg <- paste0("[", timestamp, "] [", exec_id, "] [", level, "] ",
                paste0(..., collapse = ""))
  message(msg)
  flush.console()

  invisible(NULL)
}


#' Log Progress Summary
#'
#' Logs a formatted progress summary showing completion percentage, counts,
#' and optional timing information.
#'
#' @param current Integer. Current ticker index
#' @param total Integer. Total number of tickers
#' @param successful Integer. Count of successful tickers
#' @param failed Integer. Count of failed tickers
#' @param phase Character. Phase name for display (default: "Fetch")
#' @param elapsed_seconds Numeric. Total elapsed time in seconds (optional)
#'
#' @return NULL (called for side effects)
#' @keywords internal
log_progress_summary <- function(current, total, successful, failed, phase = "Fetch",
                                  elapsed_seconds = NULL) {
  pct <- round(100 * current / total, 1)

  if (!is.null(elapsed_seconds) && current > 0) {
    avg_seconds <- elapsed_seconds / current
    remaining <- total - current
    eta_seconds <- remaining * avg_seconds
    eta_min <- round(eta_seconds / 60, 1)

    log_pipeline(
      sprintf("[%d/%d] %s%% | %d ok | %d err | %.1fs/ticker | ETA: %.1f min",
              current, total, pct, successful, failed, avg_seconds, eta_min),
      level = "INFO"
    )
  } else {
    log_pipeline(
      sprintf("[%d/%d] %s%% complete | %d successful | %d failed | Phase: %s",
              current, total, pct, successful, failed, phase),
      level = "INFO"
    )
  }

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


#' Log Failed Tickers Summary
#'
#' Logs a summary of failed tickers at the end of a phase.
#' Shows first 20 tickers inline, indicates if more exist.
#'
#' @param failed_tickers Character vector. Tickers that failed
#'
#' @return NULL (called for side effects)
#' @keywords internal
log_failed_tickers <- function(failed_tickers) {
  n_failed <- length(failed_tickers)
  if (n_failed == 0) {
    return(invisible(NULL))
  }

  if (n_failed <= 20) {
    log_pipeline(
      sprintf("Failed tickers (%d): %s", n_failed, paste(failed_tickers, collapse = ", "))
    )
  } else {
    shown <- paste(failed_tickers[1:20], collapse = ", ")
    log_pipeline(
      sprintf("Failed tickers (%d): %s, ... (+%d more)", n_failed, shown, n_failed - 20)
    )
  }

  invisible(NULL)
}
