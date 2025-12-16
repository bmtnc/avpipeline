#' Detect if New Data Contains Changes
#'
#' Compares new data to existing data to determine if there are actual changes.
#'
#' @param existing_data data.frame: Previously stored data (can be NULL)
#' @param new_data data.frame: Newly fetched data
#' @param date_column character: Column name to use for comparison (e.g., "fiscalDateEnding")
#' @return list: has_changes (logical), new_records_count (integer), latest_date (Date or NULL)
#' @keywords internal
detect_data_changes <- function(existing_data, new_data, date_column) {
  validate_df_type(new_data)
  validate_character_scalar(date_column, allow_empty = FALSE, name = "date_column")
  if (!date_column %in% names(new_data)) {
    stop(paste0(
      "detect_data_changes(): [date_column] '",
      date_column,
      "' not found in new_data"
    ))
  }
  if (is.null(existing_data) || nrow(existing_data) == 0) {
    return(list(
      has_changes = TRUE,
      new_records_count = nrow(new_data),
      latest_date = if (nrow(new_data) > 0) {
        max(new_data[[date_column]], na.rm = TRUE)
      } else {
        NULL
      }
    ))
  }
  if (!date_column %in% names(existing_data)) {
    stop(paste0(
      "detect_data_changes(): [date_column] '",
      date_column,
      "' not found in existing_data"
    ))
  }

  existing_dates <- existing_data[[date_column]]
  new_dates <- new_data[[date_column]]

  existing_max <- max(existing_dates, na.rm = TRUE)
  new_max <- max(new_dates, na.rm = TRUE)

  # Check if new data has later dates
  has_new_dates <- new_max > existing_max

  # Count records not in existing data
  new_records <- sum(!new_dates %in% existing_dates)

  list(
    has_changes = has_new_dates || new_records > 0,
    new_records_count = new_records,
    latest_date = new_max
  )
}
