#' Check if Quarterly Data Should Be Fetched
#'
#' Determines if quarterly data should be fetched based on earnings timing.
#'
#' @param next_estimated_report_date Date: Predicted next earnings date (can be NA)
#' @param quarterly_last_fetched_at POSIXct: Last fetch timestamp (can be NA)
#' @param reference_date Date: Date to check against (defaults to today)
#' @param window_days integer: Days before/after earnings to trigger fetch (default: 5)
#' @param fallback_max_days integer: Force fetch if data older than this (default: 90)
#' @return logical: TRUE if quarterly data should be fetched
#' @keywords internal
should_fetch_quarterly_data <- function(next_estimated_report_date,
                                         quarterly_last_fetched_at,
                                         reference_date = Sys.Date(),
                                         window_days = DATA_TYPE_REFRESH_CONFIG$quarterly$window_days,
                                         fallback_max_days = DATA_TYPE_REFRESH_CONFIG$quarterly$fallback_max_days) {
  if (!inherits(reference_date, "Date")) {
    stop("should_fetch_quarterly_data(): [reference_date] must be a Date object")
  }

  # New ticker - no prior fetch

if (is.na(quarterly_last_fetched_at)) {
    return(TRUE)
  }

  # Fallback: fetch if data is too old
  days_since_fetch <- as.numeric(difftime(reference_date, as.Date(quarterly_last_fetched_at), units = "days"))
  if (days_since_fetch > fallback_max_days) {
    return(TRUE)
  }

  # No predicted date - rely on fallback
  if (is.na(next_estimated_report_date)) {
    return(FALSE)
  }

  # Within ±window_days of predicted earnings
  days_until_earnings <- as.numeric(difftime(next_estimated_report_date, reference_date, units = "days"))
  abs(days_until_earnings) <= window_days
}

#' Calculate Next Estimated Report Date
#'
#' Predicts the next earnings report date based on historical patterns.
#'
#' @param last_fiscal_date_ending Date: Most recent quarter end date
#' @param last_reported_date Date: Most recent actual report date
#' @param median_report_delay_days integer: Historical median days from quarter-end to report (default: 45)
#' @return Date: Predicted next earnings report date
#' @keywords internal
calculate_next_estimated_report_date <- function(last_fiscal_date_ending,
                                                  last_reported_date,
                                                  median_report_delay_days = 45L) {
  if (is.na(last_fiscal_date_ending)) {
    return(as.Date(NA))
  }

  # Next quarter end is ~91 days after last quarter end
  next_fiscal_date <- last_fiscal_date_ending + 91L

  # If we have historical delay data, use it; otherwise use default
  delay <- if (is.na(median_report_delay_days)) 45L else median_report_delay_days

  next_fiscal_date + delay
}

#' Calculate Median Report Delay
#'
#' Calculates the median delay between quarter end and report date from historical data.
#'
#' @param earnings_data data.frame: Earnings data with fiscalDateEnding and reportedDate
#' @return integer: Median delay in days, or NA if insufficient data
#' @keywords internal
calculate_median_report_delay <- function(earnings_data) {
  if (!is.data.frame(earnings_data)) {
    stop("calculate_median_report_delay(): [earnings_data] must be a data.frame")
  }

  if (nrow(earnings_data) == 0) {
    return(NA_integer_)
  }

  required_cols <- c("fiscalDateEnding", "reportedDate")
  if (!all(required_cols %in% names(earnings_data))) {
    stop("calculate_median_report_delay(): [earnings_data] must have fiscalDateEnding and reportedDate columns")
  }

  # Filter to rows with both dates
  valid_rows <- earnings_data[!is.na(earnings_data$fiscalDateEnding) & !is.na(earnings_data$reportedDate), ]

  if (nrow(valid_rows) < 2) {
    return(NA_integer_)
  }

  delays <- as.numeric(difftime(valid_rows$reportedDate, valid_rows$fiscalDateEnding, units = "days"))

  as.integer(round(median(delays, na.rm = TRUE)))
}

#' Determine Fetch Requirements for a Ticker
#'
#' Determines which data types need to be fetched for a ticker based on tracking state.
#'
#' @param ticker_tracking tibble: Single row from refresh tracking for this ticker
#' @param reference_date Date: Date to check against (defaults to today)
#' @return list: Named list with price, splits, quarterly (each TRUE/FALSE)
#' @keywords internal
determine_fetch_requirements <- function(ticker_tracking, reference_date = Sys.Date()) {
  if (!is.data.frame(ticker_tracking) || nrow(ticker_tracking) != 1) {
    stop("determine_fetch_requirements(): [ticker_tracking] must be a single-row data.frame")
  }
  if (!inherits(reference_date, "Date")) {
    stop("determine_fetch_requirements(): [reference_date] must be a Date object")
  }

  # Price and splits: always fetch on scheduled runs
  fetch_price <- TRUE
  fetch_splits <- TRUE

  # Quarterly: smart refresh based on earnings timing
  fetch_quarterly <- should_fetch_quarterly_data(
    next_estimated_report_date = ticker_tracking$next_estimated_report_date,
    quarterly_last_fetched_at = ticker_tracking$quarterly_last_fetched_at,
    reference_date = reference_date
  )

  list(
    price = fetch_price,
    splits = fetch_splits,
    quarterly = fetch_quarterly
  )
}

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
  if (!is.data.frame(new_data)) {
    stop("detect_data_changes(): [new_data] must be a data.frame")
  }
  if (!is.character(date_column) || length(date_column) != 1) {
    stop("detect_data_changes(): [date_column] must be a character scalar")
  }
  if (!date_column %in% names(new_data)) {
    stop(paste0("detect_data_changes(): [date_column] '", date_column, "' not found in new_data"))
  }

  # No existing data - everything is new
  if (is.null(existing_data) || nrow(existing_data) == 0) {
    return(list(
      has_changes = TRUE,
      new_records_count = nrow(new_data),
      latest_date = if (nrow(new_data) > 0) max(new_data[[date_column]], na.rm = TRUE) else NULL
    ))
  }

  if (!date_column %in% names(existing_data)) {
    stop(paste0("detect_data_changes(): [date_column] '", date_column, "' not found in existing_data"))
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

#' Update Earnings Prediction After Fetch
#'
#' Updates the tracking with new earnings prediction based on freshly fetched data.
#'
#' @param tracking tibble: Full refresh tracking dataframe
#' @param ticker character: Stock symbol
#' @param earnings_data data.frame: Freshly fetched earnings data
#' @return tibble: Updated tracking dataframe
#' @keywords internal
update_earnings_prediction <- function(tracking, ticker, earnings_data) {
  if (!is.data.frame(tracking)) {
    stop("update_earnings_prediction(): [tracking] must be a data.frame")
  }
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("update_earnings_prediction(): [ticker] must be a character scalar")
  }
  if (!is.data.frame(earnings_data)) {
    stop("update_earnings_prediction(): [earnings_data] must be a data.frame")
  }

  if (nrow(earnings_data) == 0) {
    return(tracking)
  }

  # Get latest dates from earnings data
  last_fiscal <- max(earnings_data$fiscalDateEnding, na.rm = TRUE)
  last_reported <- max(earnings_data$reportedDate, na.rm = TRUE)

  # Calculate median delay
  median_delay <- calculate_median_report_delay(earnings_data)

  # Predict next report date
  next_estimated <- calculate_next_estimated_report_date(
    last_fiscal_date_ending = last_fiscal,
    last_reported_date = last_reported,
    median_report_delay_days = median_delay
  )

  # Update tracking
  update_ticker_tracking(tracking, ticker, list(
    last_fiscal_date_ending = last_fiscal,
    last_reported_date = last_reported,
    median_report_delay_days = median_delay,
    next_estimated_report_date = next_estimated
  ))
}
