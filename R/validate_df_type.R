#' Validate DataFrame Type
#'
#' Validates that an object is a data.frame.
#' This function is called for its side effects and will stop execution with
#' an error message if validation fails.
#'
#' @param data Object to validate as a data.frame
#'
#' @return NULL (called for side effects)
#' @export
validate_df_type <- function(data) {
  if (!is.data.frame(data)) {
    stop(paste0("Input data must be a data.frame. Received: ", class(data)[1]))
  }
}
