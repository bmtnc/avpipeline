#' Check if Price Data Contains Split
#'
#' Checks if any records in price data have a split coefficient != 1.0.
#'
#' @param price_data tibble: Price data from API (must have split_coefficient column)
#' @return logical: TRUE if split detected, FALSE otherwise
#' @keywords internal
price_data_contains_split <- function(price_data) {
  if (is.null(price_data) || nrow(price_data) == 0) {
    return(FALSE)
  }

  if (!"split_coefficient" %in% names(price_data)) {
    return(FALSE)
  }

  any(price_data$split_coefficient != 1.0, na.rm = TRUE)
}
