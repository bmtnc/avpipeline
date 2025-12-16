#' Validate Numeric Vector
#'
#' Validates that an object is a numeric vector.
#' Optionally checks that the vector is non-empty.
#'
#' @param x Object to validate
#' @param allow_empty Logical. If FALSE, rejects empty vectors. Default FALSE.
#' @param name Optional name for the parameter (used in error messages)
#'
#' @return NULL (called for side effects)
#' @keywords internal
validate_numeric_vector <- function(x, allow_empty = FALSE, name = "Input") {
  if (!is.numeric(x)) {
    stop(paste0(
      name, " must be a numeric vector. Received: ", class(x)[1]
    ))
  }
  if (!allow_empty && length(x) == 0) {
    stop(paste0(name, " must not be empty"))
  }
}
