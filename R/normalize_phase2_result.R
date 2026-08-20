#' Normalize a Single Phase 2 Worker Result into a Log Record
#'
#' Maps one worker return value onto the pipeline log schema. A worker can
#' return three shapes and each must be distinguishable in the log: a
#' well-formed record, a bare NULL, or a `try-error`.
#'
#' A killed fork (OOM, segfault) surfaces as NULL under `mc.preschedule = TRUE`
#' — mclapply's default and what Phase 2 uses — with the whole scheduled chunk
#' NULLed and a "did not deliver a result" warning; it surfaces as `try-error`
#' only under `mc.preschedule = FALSE`. Both are logged as errors, since
#' recording them as "skipped" would let a mass worker kill read as a clean run.
#'
#' @param result Worker return value for one ticker
#' @param ticker character: Ticker the result belongs to
#' @param data_type character: Log data_type label
#' @return tibble: Single-row pipeline log entry
#' @keywords internal
normalize_phase2_result <- function(result, ticker, data_type) {
  log_entry <- function(status, rows, error_message, duration_seconds) {
    tibble::tibble(
      ticker = ticker,
      phase = "generate",
      data_type = data_type,
      status = status,
      rows = as.integer(rows),
      error_message = error_message,
      duration_seconds = duration_seconds,
      timestamp = Sys.time()
    )
  }

  if (inherits(result, "try-error")) {
    return(log_entry(
      "error",
      0L,
      paste0("worker terminated: ", as.character(result)),
      NA_real_
    ))
  }

  if (!is.list(result) || is.null(result$status)) {
    return(log_entry(
      "error",
      0L,
      "worker returned no result record (likely killed: OOM or segfault)",
      NA_real_
    ))
  }

  log_entry(
    status = result$status,
    rows = if (is.null(result$rows)) 0L else result$rows,
    error_message = if (is.null(result$error_message)) {
      NA_character_
    } else {
      result$error_message
    },
    duration_seconds = if (is.null(result$duration_seconds)) {
      NA_real_
    } else {
      result$duration_seconds
    }
  )
}
