#' Validate DataFrame is Not Empty
#'
#' Validates that a data.frame has at least one row.
#' This function is called for its side effects and will stop execution with
#' an error message if validation fails.
#'
#' @param data data.frame to validate
#'
#' @return NULL (called for side effects)
#' @keywords internal
validate_df_not_empty <- function(data) {
  if (nrow(data) == 0) {
    stop("Input data is empty (0 rows)")
  }
}
