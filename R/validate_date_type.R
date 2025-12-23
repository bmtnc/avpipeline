#' Validate Date Type
#'
#' Validates that an object is a Date. Optionally checks that it is a scalar (length 1).
#'
#' @param x Object to validate
#' @param scalar Logical. If TRUE, requires length 1. Default TRUE.
#' @param name Optional name for the parameter (used in error messages)
#'
#' @return NULL (called for side effects)
#' @export
validate_date_type <- function(x, scalar = TRUE, name = "Input") {
  if (!inherits(x, "Date")) {
    stop(paste0(
      name, " must be a Date object. Received: ", class(x)[1]
    ))
  }
  if (scalar && length(x) != 1) {
    stop(paste0(
      name, " must be a Date scalar (length 1). Received length: ", length(x)
    ))
  }
}
