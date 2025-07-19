#' Extract Quarterly Reporting Pattern
#'
#' Generates a company's expected quarterly reporting dates based on their first
#' reporting date. Starting from the first date, extracts every 3rd month from
#' a monthly date sequence to create the company-specific fiscal quarter pattern.
#'
#' @param first_date Date object representing the company's first reporting date
#' @param last_date Date object representing the company's last reporting date
#' @param monthly_dates Vector of Date objects representing monthly month-end dates
#'
#' @return Vector of Date objects representing the expected quarterly reporting
#'   pattern for this company from first_date through last_date inclusive
#' @export
extract_quarterly_pattern <- function(first_date, last_date, monthly_dates) {
  
  # Input validation
  if (!inherits(first_date, "Date")) {
    stop(paste0("Input 'first_date' must be a Date object. Received: ", 
                class(first_date)[1]))
  }
  
  if (!inherits(last_date, "Date")) {
    stop(paste0("Input 'last_date' must be a Date object. Received: ", 
                class(last_date)[1]))
  }
  
  if (!inherits(monthly_dates, "Date")) {
    stop(paste0("Input 'monthly_dates' must be a vector of Date objects. Received: ", 
                class(monthly_dates)[1]))
  }
  
  if (length(first_date) != 1) {
    stop(paste0("Input 'first_date' must be a single Date value. Received length: ", 
                length(first_date)))
  }
  
  if (length(last_date) != 1) {
    stop(paste0("Input 'last_date' must be a single Date value. Received length: ", 
                length(last_date)))
  }
  
  if (length(monthly_dates) == 0) {
    stop("Input 'monthly_dates' cannot be empty")
  }
  
  if (first_date > last_date) {
    stop(paste0("Input 'first_date' (", as.character(first_date), 
                ") must be less than or equal to 'last_date' (", as.character(last_date), ")"))
  }
  
  # Validate that first_date exists in monthly_dates
  if (!first_date %in% monthly_dates) {
    stop(paste0("Input 'first_date' (", as.character(first_date), 
                ") must be present in 'monthly_dates' sequence"))
  }
  
  # Find starting position of first_date in monthly sequence
  start_position <- which(monthly_dates == first_date)[1]
  
  # Extract quarterly pattern (every 3rd month starting from first_date)
  quarterly_dates <- c()
  current_position <- start_position
  
  while (current_position <= length(monthly_dates)) {
    current_date <- monthly_dates[current_position]
    
    # Stop if we've exceeded the last_date
    if (current_date > last_date) {
      break
    }
    
    quarterly_dates <- c(quarterly_dates, current_date)
    current_position <- current_position + 3  # Move 3 months forward
  }
  
  # Ensure return value maintains Date class
  as.Date(quarterly_dates, origin = "1970-01-01")
}