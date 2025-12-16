#' Validate Numeric Scalar
#'
#' Validates that an object is a single numeric value.
#' Optionally checks bounds (greater than, greater or equal, less than, etc.).
#'
#' @param x Object to validate
#' @param name Optional name for the parameter (used in error messages)
#' @param gt Greater than bound (exclusive). Default NULL (no check).
#' @param gte Greater than or equal bound. Default NULL (no check).
#' @param lt Less than bound (exclusive). Default NULL (no check).
#' @param lte Less than or equal bound. Default NULL (no check).
#'
#' @return NULL (called for side effects)
#' @keywords internal
validate_numeric_scalar <- function(x, name = "Input", gt = NULL, gte = NULL,
                                    lt = NULL, lte = NULL) {
  if (!is.numeric(x) || length(x) != 1) {
    stop(paste0(
      name, " must be a numeric scalar (length 1). ",
      "Received: ", class(x)[1], " of length ", length(x)
    ))
  }
  if (is.na(x)) {
    stop(paste0(name, " must not be NA"))
  }
  if (!is.null(gt) && x <= gt) {
    stop(paste0(name, " must be greater than ", gt, ". Received: ", x))
  }
  if (!is.null(gte) && x < gte) {
    stop(paste0(name, " must be >= ", gte, ". Received: ", x))
  }
  if (!is.null(lt) && x >= lt) {
    stop(paste0(name, " must be less than ", lt, ". Received: ", x))
  }
  if (!is.null(lte) && x > lte) {
    stop(paste0(name, " must be <= ", lte, ". Received: ", x))
  }
}
