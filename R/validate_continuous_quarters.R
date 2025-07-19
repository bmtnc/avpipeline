#' Validate Continuous Quarterly Series
#'
#' Validates that a company has continuous quarterly reporting by generating
#' company-specific expected quarterly dates and comparing against actual reporting dates.
#' Uses the company's first reporting date to establish their fiscal quarter pattern.
#'
#' @param ticker_data Data frame containing a single ticker's time series data
#' @param date_col Character string specifying the column name containing fiscal date endings
#'   (default: "fiscalDateEnding")
#' @param row_num_col Character string specifying the column name that contains row numbers
#'   for filtering (default: "row_num")
#' @param cleanup_cols Character vector of column names to remove from the final output
#'   (default: c("days_diff", "is_quarterly", "row_num"))
#'
#' @return Data frame containing the continuous quarterly series from the identified start
#'   point onward, with cleanup columns removed. Returns empty data frame if no continuous
#'   quarterly series is found.
#' @export
validate_continuous_quarters <- function(ticker_data,
                                         date_col = "fiscalDateEnding",
                                         row_num_col = "row_num", 
                                         cleanup_cols = c("days_diff", "is_quarterly", "row_num")) {
  
  # Input validation
  if (!is.character(date_col) || length(date_col) != 1) {
    stop(paste0("Input 'date_col' must be a single character string. Received: ",
                class(date_col)[1], " of length ", length(date_col)))
  }
  
  if (!is.character(row_num_col) || length(row_num_col) != 1) {
    stop(paste0("Input 'row_num_col' must be a single character string. Received: ",
                class(row_num_col)[1], " of length ", length(row_num_col)))
  }
  
  if (!is.character(cleanup_cols)) {
    stop(paste0("Input 'cleanup_cols' must be a character vector. Received: ",
                class(cleanup_cols)[1]))
  }
  
  # Validate data frame and required columns
  required_cols <- c(date_col, row_num_col)
  validate_df_cols(ticker_data, required_cols)
  
  # Pre-filter to only valid month-end dates
  actual_dates <- ticker_data[[date_col]]
  
  is_month_end <- sapply(actual_dates, function(date) {
    tryCatch({
      validate_month_end_date(date, "date")
      TRUE
    }, error = function(e) {
      FALSE
    })
  })
  
  # Filter ticker_data to only valid month-end dates
  filtered_data <- ticker_data[is_month_end, ]
  
  # If no valid month-end dates, return empty
  if (nrow(filtered_data) == 0) {
    return(ticker_data[0, ] %>% dplyr::select(-dplyr::any_of(cleanup_cols)))
  }
  
  # Get dates from filtered data
  filtered_dates <- filtered_data[[date_col]]
  
  # Generate comprehensive monthly sequence for date range
  min_date <- min(filtered_dates)
  max_date <- max(filtered_dates)
  monthly_dates <- generate_month_end_dates(min_date, max_date)
  
  # For each actual date, try it as a potential quarterly starting point
  best_start_idx <- NULL
  max_length <- 0
  
  for (i in seq_along(filtered_dates)) {
    start_date <- filtered_dates[i]
    
    # Generate expected quarterly pattern starting from this date
    expected_quarters <- extract_quarterly_pattern(start_date, max_date, monthly_dates)
    
    # Count consecutive matches starting from this position
    current_length <- 0
    
    for (j in seq_along(expected_quarters)) {
      actual_pos <- i + j - 1
      
      # Check if we have enough actual dates remaining
      if (actual_pos > length(filtered_dates)) break
      
      # Check if actual date matches expected date
      if (filtered_dates[actual_pos] != expected_quarters[j]) break
      
      current_length <- j
    }
    
    # Update best sequence if this one is longer
    if (current_length > max_length) {
      max_length <- current_length
      best_start_idx <- i
    }
  }
  
# ... existing code until the final return section ...

  # Return filtered data from best continuous start point
  if (!is.null(best_start_idx) && max_length > 0) {
    # Return only the continuous quarterly sequence (max_length records)
    continuous_end_idx <- best_start_idx + max_length - 1
    
    # Only auto-add row_num_col if using default cleanup_cols and it's not "row_num"
    final_cleanup_cols <- cleanup_cols
    default_cleanup <- c("days_diff", "is_quarterly", "row_num")
    
    if (identical(cleanup_cols, default_cleanup) && row_num_col != "row_num") {
      final_cleanup_cols <- c(cleanup_cols[cleanup_cols != "row_num"], row_num_col)
    }
    
    filtered_data[best_start_idx:continuous_end_idx, ] %>%
      dplyr::select(-dplyr::any_of(final_cleanup_cols))
  } else {
    # No continuous series found
    final_cleanup_cols <- cleanup_cols
    default_cleanup <- c("days_diff", "is_quarterly", "row_num")
    
    if (identical(cleanup_cols, default_cleanup) && row_num_col != "row_num") {
      final_cleanup_cols <- c(cleanup_cols[cleanup_cols != "row_num"], row_num_col)
    }
    
    ticker_data[0, ] %>%
      dplyr::select(-dplyr::any_of(final_cleanup_cols))
  }    
}