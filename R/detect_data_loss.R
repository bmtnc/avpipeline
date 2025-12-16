#' Check for Data Loss (Fewer Quarters Than Before)
#'
#' Detects if new data has fewer records than existing data (potential data loss).
#'
#' @param existing_data data.frame: Previously stored data
#' @param new_data data.frame: Newly fetched data
#' @param date_column character: Column to count unique dates
#' @return list: has_loss (logical), existing_count (integer), new_count (integer)
#' @keywords internal
detect_data_loss <- function(
  existing_data,
  new_data,
  date_column = "fiscalDateEnding"
) {
  if (is.null(existing_data) || nrow(existing_data) == 0) {
    return(list(
      has_loss = FALSE,
      existing_count = 0L,
      new_count = nrow(new_data)
    ))
  }
  validate_df_type(new_data)
  if (
    !date_column %in% names(existing_data) || !date_column %in% names(new_data)
  ) {
    return(list(
      has_loss = FALSE,
      existing_count = NA_integer_,
      new_count = NA_integer_
    ))
  }

  existing_count <- length(unique(existing_data[[date_column]]))
  new_count <- length(unique(new_data[[date_column]]))

  list(
    has_loss = new_count < existing_count,
    existing_count = as.integer(existing_count),
    new_count = as.integer(new_count)
  )
}
