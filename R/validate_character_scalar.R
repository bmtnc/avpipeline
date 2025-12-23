#' Validate Character Scalar
#'
#' Validates that an object is a single character string.
#' Optionally checks that the string is non-empty.
#'
#' @param x Object to validate
#' @param allow_empty Logical. If FALSE, rejects empty strings. Default TRUE.
#' @param name Optional name for the parameter (used in error messages)
#'
#' @return NULL (called for side effects)
#' @export
validate_character_scalar <- function(x, allow_empty = TRUE, name = "Input") {
  if (!is.character(x) || length(x) != 1) {
    stop(paste0(
      name, " must be a character scalar (length 1). ",
      "Received: ", class(x)[1], " of length ", length(x)
    ))
  }
  if (!allow_empty && !nzchar(x)) {
    stop(paste0(name, " must be a non-empty string"))
  }
}
