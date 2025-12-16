#' Validate File Exists
#'
#' Validates that a file exists at the specified path.
#'
#' @param file_path Character scalar path to the file
#' @param name Optional name for the parameter (used in error messages)
#'
#' @return NULL (called for side effects)
#' @keywords internal
validate_file_exists <- function(file_path, name = "File") {
  validate_character_scalar(file_path, allow_empty = FALSE, name = name)
  if (!file.exists(file_path)) {
    stop(paste0(name, " does not exist: ", file_path))
  }
}
