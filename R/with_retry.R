#' Execute Expression with Exponential Backoff Retry
#'
#' Retries an expression on failure with exponential backoff. Only retries
#' for errors matching specified patterns (e.g., rate limits, timeouts).
#'
#' @param expr Expression to execute
#' @param max_attempts Integer. Maximum number of attempts (default: 3)
#' @param initial_delay Numeric. Initial delay in seconds (default: 5)
#' @param backoff_multiplier Numeric. Multiplier for each retry (default: 2)
#' @param retryable_errors Character. Regex pattern for retryable errors
#'   (default: "rate limit|timeout|connection|timed out")
#'
#' @return Result of expr if successful
#' @keywords internal
with_retry <- function(expr,
                       max_attempts = 3,
                       initial_delay = 5,
                       backoff_multiplier = 2,
                       retryable_errors = "rate limit|timeout|connection|timed out") {
  validate_positive(max_attempts, name = "max_attempts")
  validate_positive(initial_delay, name = "initial_delay")
  validate_positive(backoff_multiplier, name = "backoff_multiplier")

  delay <- initial_delay
  last_error <- NULL


  for (attempt in seq_len(max_attempts)) {
    result <- tryCatch(
      expr,
      error = function(e) e
    )

    if (!inherits(result, "error")) {
      return(result)
    }

    last_error <- result

    if (!grepl(retryable_errors, result$message, ignore.case = TRUE)) {
      stop(result)
    }

    if (attempt < max_attempts) {
      log_pipeline(
        sprintf("Retryable error (attempt %d/%d): %s. Waiting %.0fs...",
                attempt, max_attempts, result$message, delay),
        level = "WARN"
      )
      Sys.sleep(delay)
      delay <- delay * backoff_multiplier
    }
  }

  stop(sprintf(
    "All %d retry attempts failed. Last error: %s",
    max_attempts, last_error$message
  ))
}
