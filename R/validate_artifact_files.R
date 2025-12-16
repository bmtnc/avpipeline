#' Validate Artifact Files Exist
#'
#' Validates that all required cache files exist before loading financial data.
#'
#' @param file_paths character: Vector of file paths to validate
#' @return invisible NULL (stops with error if files are missing)
#' @keywords internal
validate_artifact_files <- function(file_paths) {
  if (!is.character(file_paths)) {
    stop(paste0(
      "validate_artifact_files(): [file_paths] must be a character vector, not ",
      class(file_paths)[1]
    ))
  }

  missing_files <- file_paths[!file.exists(file_paths)]

  if (length(missing_files) > 0) {
    stop(paste0(
      "validate_artifact_files(): Missing required files: ",
      paste(missing_files, collapse = ", ")
    ))
  }

  invisible(NULL)
}
