#' Validate Month End Date
#'
#' Validates that a date is a month-end date (last day of the month).
#' This function is called for its side effects and will stop execution
#' with an error message if validation fails.
#'
#' @param date Date object to validate as a month-end date
#' @param param_name Character string specifying the parameter name for error messages
#'
#' @return NULL (called for side effects)
#' @export
validate_month_end_date <- function(date, param_name) {
  
  # Input validation
  if (!inherits(date, "Date")) {
    stop(paste0("Input '", param_name, "' must be a Date object. Received: ", 
                class(date)[1]))
  }
  
  if (length(date) != 1) {
    stop(paste0("Input '", param_name, "' must be a single Date value. Received length: ", 
                length(date)))
  }
  
  # Check if date is a month-end date
  day <- lubridate::day(date)
  last_day_of_month <- lubridate::days_in_month(date)
  
  if (day != last_day_of_month) {
    expected_date <- lubridate::ceiling_date(date, "month") - lubridate::days(1)
    stop(paste0("Input '", param_name, "' (", as.character(date), 
                ") must be a month-end date. Expected: ", as.character(expected_date)))
  }
}