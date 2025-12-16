#' Create Empty Refresh Tracking DataFrame
#'
#' Creates an empty dataframe with the refresh tracking schema.
#'
#' @return tibble: Empty dataframe with correct column types
#' @keywords internal
create_empty_refresh_tracking <- function() {
  tibble::tibble(
    ticker = character(),
    price_last_fetched_at = as.POSIXct(character()),
    splits_last_fetched_at = as.POSIXct(character()),
    quarterly_last_fetched_at = as.POSIXct(character()),
    last_fiscal_date_ending = as.Date(character()),
    last_reported_date = as.Date(character()),
    next_estimated_report_date = as.Date(character()),
    median_report_delay_days = integer(),
    last_error_message = character(),
    is_active_ticker = logical(),
    has_data_discrepancy = logical(),
    last_version_date = as.Date(character()),
    data_updated_at = as.POSIXct(character())
  )
}

#' Create Default Tracking Row for New Ticker
#'
#' Creates a default tracking row for a ticker not yet in tracking.
#'
#' @param ticker character: Stock symbol
#' @return tibble: Single row with default values
#' @keywords internal
create_default_ticker_tracking <- function(ticker) {
  if (!is.character(ticker) || length(ticker) != 1 || nchar(ticker) == 0) {
    stop("create_default_ticker_tracking(): [ticker] must be a non-empty character scalar")
  }

  tibble::tibble(
    ticker = ticker,
    price_last_fetched_at = as.POSIXct(NA),
    splits_last_fetched_at = as.POSIXct(NA),
    quarterly_last_fetched_at = as.POSIXct(NA),
    last_fiscal_date_ending = as.Date(NA),
    last_reported_date = as.Date(NA),
    next_estimated_report_date = as.Date(NA),
    median_report_delay_days = NA_integer_,
    last_error_message = NA_character_,
    is_active_ticker = TRUE,
    has_data_discrepancy = FALSE,
    last_version_date = as.Date(NA),
    data_updated_at = as.POSIXct(NA)
  )
}

#' Read Refresh Tracking from S3
#'
#' Downloads the refresh tracking dataframe from S3. Returns empty tracking if not found.
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return tibble: Refresh tracking dataframe
#' @keywords internal
s3_read_refresh_tracking <- function(bucket_name, region = "us-east-1") {
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("s3_read_refresh_tracking(): [bucket_name] must be a character scalar")
  }

  s3_key <- "raw/_metadata/refresh_tracking.parquet"
  s3_uri <- paste0("s3://", bucket_name, "/", s3_key)

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  result <- system2("aws",
                    args = c("s3", "cp", s3_uri, temp_file, "--region", region),
                    stdout = TRUE,
                    stderr = TRUE)

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    message("No existing refresh tracking found, creating empty tracking")
    return(create_empty_refresh_tracking())
  }

  if (!file.exists(temp_file)) {
    return(create_empty_refresh_tracking())
  }

  arrow::read_parquet(temp_file)
}

#' Write Refresh Tracking to S3
#'
#' Uploads the refresh tracking dataframe to S3.
#'
#' @param tracking tibble: Refresh tracking dataframe
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if upload successful
#' @keywords internal
s3_write_refresh_tracking <- function(tracking, bucket_name, region = "us-east-1") {
  if (!is.data.frame(tracking)) {
    stop("s3_write_refresh_tracking(): [tracking] must be a data.frame")
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("s3_write_refresh_tracking(): [bucket_name] must be a character scalar")
  }

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  arrow::write_parquet(tracking, temp_file)

  s3_key <- "raw/_metadata/refresh_tracking.parquet"
  upload_artifact_to_s3(temp_file, bucket_name, s3_key, region)
}

#' Get Tracking for a Single Ticker
#'
#' Retrieves tracking row for a ticker, or creates default if not found.
#'
#' @param ticker character: Stock symbol
#' @param tracking tibble: Full refresh tracking dataframe
#' @return tibble: Single row for the ticker
#' @keywords internal
get_ticker_tracking <- function(ticker, tracking) {
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("get_ticker_tracking(): [ticker] must be a character scalar")
  }
  if (!is.data.frame(tracking)) {
    stop("get_ticker_tracking(): [tracking] must be a data.frame")
  }

  ticker_row <- dplyr::filter(tracking, ticker == !!ticker)


  if (nrow(ticker_row) == 0) {
    return(create_default_ticker_tracking(ticker))
  }

  ticker_row
}

#' Update Tracking for a Single Ticker
#'
#' Updates the tracking dataframe with new values for a ticker.
#'
#' @param tracking tibble: Full refresh tracking dataframe
#' @param ticker character: Stock symbol
#' @param updates list: Named list of columns to update
#' @return tibble: Updated tracking dataframe
#' @keywords internal
update_ticker_tracking <- function(tracking, ticker, updates) {
  if (!is.data.frame(tracking)) {
    stop("update_ticker_tracking(): [tracking] must be a data.frame")
  }
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("update_ticker_tracking(): [ticker] must be a character scalar")
  }
  if (!is.list(updates)) {
    stop("update_ticker_tracking(): [updates] must be a list")
  }

  ticker_exists <- ticker %in% tracking$ticker

  if (!ticker_exists) {
    new_row <- create_default_ticker_tracking(ticker)
    for (col in names(updates)) {
      if (col %in% names(new_row)) {
        new_row[[col]] <- updates[[col]]
      }
    }
    return(dplyr::bind_rows(tracking, new_row))
  }

  for (col in names(updates)) {
    if (col %in% names(tracking)) {
      tracking <- dplyr::mutate(tracking,
        !!col := dplyr::if_else(ticker == !!ticker, updates[[col]], .data[[col]])
      )
    }
  }

  tracking
}

#' Update Tracking After Successful Fetch
#'
#' Convenience function to update tracking after fetching data for a ticker.
#'
#' @param tracking tibble: Full refresh tracking dataframe
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data fetched ("price", "splits", or "quarterly")
#' @param fiscal_date_ending Date: Most recent fiscalDateEnding (for quarterly only)
#' @param reported_date Date: Most recent reportedDate (for quarterly only)
#' @param data_changed logical: Whether data actually changed from previous fetch
#' @return tibble: Updated tracking dataframe
#' @keywords internal
update_tracking_after_fetch <- function(tracking, ticker, data_type,
                                         fiscal_date_ending = NULL,
                                         reported_date = NULL,
                                         data_changed = FALSE) {
  if (!is.character(data_type) || length(data_type) != 1) {
    stop("update_tracking_after_fetch(): [data_type] must be a character scalar")
  }

  now <- Sys.time()
  updates <- list()

  if (data_type == "price") {
    updates$price_last_fetched_at <- now
  } else if (data_type == "splits") {
    updates$splits_last_fetched_at <- now
  } else if (data_type == "quarterly") {
    updates$quarterly_last_fetched_at <- now
    if (!is.null(fiscal_date_ending)) {
      updates$last_fiscal_date_ending <- fiscal_date_ending
    }
    if (!is.null(reported_date)) {
      updates$last_reported_date <- reported_date
    }
  }

  if (data_changed) {
    updates$data_updated_at <- now
  }

  updates$last_error_message <- NA_character_

  update_ticker_tracking(tracking, ticker, updates)
}

#' Update Tracking After Error
#'
#' Updates tracking to record an error for a ticker.
#'
#' @param tracking tibble: Full refresh tracking dataframe
#' @param ticker character: Stock symbol
#' @param error_message character: Error message to record
#' @return tibble: Updated tracking dataframe
#' @keywords internal
update_tracking_after_error <- function(tracking, ticker, error_message) {
  if (!is.character(error_message) || length(error_message) != 1) {
    stop("update_tracking_after_error(): [error_message] must be a character scalar")
  }

  update_ticker_tracking(tracking, ticker, list(last_error_message = error_message))
}
