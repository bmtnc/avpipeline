#' Execute Expression with Timeout
#'
#' Wraps an expression with a timeout limit. Returns a fallback value if timeout
#' is exceeded.
#'
#' @param expr Expression to execute
#' @param timeout_seconds Numeric. Maximum time in seconds to allow
#' @param on_timeout Value to return if timeout is exceeded (default: NULL)
#'
#' @return Result of expr, or on_timeout value if timeout exceeded
#' @keywords internal
with_timeout <- function(expr, timeout_seconds, on_timeout = NULL) {
  validate_positive(timeout_seconds, name = "timeout_seconds")

  setTimeLimit(cpu = timeout_seconds, elapsed = timeout_seconds, transient = TRUE)
  on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE), add = TRUE)

  tryCatch(
    expr,
    error = function(e) {
      if (grepl("reached elapsed time limit|reached CPU time limit", e$message)) {
        warning("Operation timed out after ", timeout_seconds, " seconds")
        on_timeout
      } else {
        stop(e)
      }
    }
  )
}
