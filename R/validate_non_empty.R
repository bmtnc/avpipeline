#' Validate Non-Empty Object
#'
#' Validates that an object is not NULL, not empty (length > 0), and for
#' data.frames, has at least one row. Use this for general non-empty checks
#' on vectors, lists, and data.frames.
#'
#' @param x Object to validate
#' @param name Optional name for the parameter (used in error messages)
#'
#' @return NULL (called for side effects)
#' @export
validate_non_empty <- function(x, name = "Input") {
  if (is.null(x)) {
    stop(paste0(name, " must not be NULL"))
  }
  # Data.frames: check nrow (length returns ncol for data.frames)
  # Other objects: check length
  if (is.data.frame(x)) {
    if (nrow(x) == 0) {
      stop(paste0(name, " data.frame must have at least one row"))
    }
  } else if (length(x) == 0) {
    stop(paste0(name, " must not be empty (length 0)"))
  }
}
