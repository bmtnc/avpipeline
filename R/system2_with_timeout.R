#' Execute system2 with Timeout
#'
#' Wrapper around system2() that adds timeout protection to prevent indefinite
#' hangs on AWS CLI or other external commands.
#'
#' @param command Character. The system command to run
#' @param args Character vector. Arguments to pass to the command
#' @param timeout_seconds Numeric. Maximum time in seconds (default: 30)
#' @param ... Additional arguments passed to system2()
#'
#' @return Output from system2(), or a timeout marker if timeout exceeded
#' @keywords internal
system2_with_timeout <- function(command, args, timeout_seconds = 30, ...) {
  validate_character_scalar(command, name = "command")
  validate_positive(timeout_seconds, name = "timeout_seconds")

  result <- with_timeout(
    system2(command, args, ...),
    timeout_seconds = timeout_seconds,
    on_timeout = structure("TIMEOUT", status = 124, class = "timeout_result")
  )

  result
}


#' Check if Result is a Timeout
#'
#' @param result Result from system2_with_timeout()
#' @return Logical TRUE if result was a timeout
#' @keywords internal
is_timeout_result <- function(result) {
  inherits(result, "timeout_result")
}
