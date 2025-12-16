#' Validate Positive Numeric
#'
#' Validates that a numeric value is positive (greater than zero).
#' A convenience wrapper around validate_numeric_scalar with gt = 0.
#'
#' @param x Object to validate
#' @param name Optional name for the parameter (used in error messages)
#'
#' @return NULL (called for side effects)
#' @keywords internal
validate_positive <- function(x, name = "Input") {
  validate_numeric_scalar(x, name = name, gt = 0)
}
