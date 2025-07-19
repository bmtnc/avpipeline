#' Generate Monthly Date Sequence
#'
#' Creates a sequence of month-end dates spanning from a start date through an end date.
#' Automatically handles leap years and varying month lengths (28-31 days). Input dates
#' should be month-end dates.
#'
#' @param start_date Date object representing the first month-end date in the sequence
#' @param end_date Date object representing the last month-end date to include
#'
#' @return Vector of Date objects representing month-end dates from start_date
#'   through end_date inclusive
#' @export
generate_month_end_dates <- function(start_date, end_date) {
  
  # Validate inputs using helper function
  validate_month_end_date(start_date, "start_date")
  validate_month_end_date(end_date, "end_date")
  
  if (start_date > end_date) {
    stop(paste0("Input 'start_date' (", as.character(start_date), 
                ") must be less than or equal to 'end_date' (", as.character(end_date), ")"))
  }
  
  # Generate monthly sequence
  monthly_dates <- c()
  current_date <- start_date
  
  while (current_date <= end_date) {
    monthly_dates <- c(monthly_dates, current_date)
    
    # Move to next month-end
    next_month_first <- lubridate::ceiling_date(current_date, "month") + lubridate::days(1)
    current_date <- lubridate::ceiling_date(next_month_first, "month") - lubridate::days(1)
  }
  
  # Ensure return value maintains Date class
  as.Date(monthly_dates, origin = "1970-01-01")
}