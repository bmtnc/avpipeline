#' Fetch Historical Options for Multiple Dates and Store in S3
#'
#' @param ticker character: Stock ticker symbol
#' @param dates Date vector: Observation dates to fetch
#' @param bucket_name character: S3 bucket name
#' @param api_key character: Alpha Vantage API key
#' @param region character: AWS region (default: "us-east-1")
#'
#' @return list with success_count, fail_count, total_rows
#' @keywords internal
fetch_historical_options_for_dates <- function(ticker,
                                                dates,
                                                bucket_name,
                                                api_key,
                                                region = "us-east-1") {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")
  validate_character_scalar(bucket_name, allow_empty = FALSE, name = "bucket_name")

  if (length(dates) == 0) {
    return(list(success_count = 0L, fail_count = 0L, total_rows = 0L))
  }

  fetched_data <- list()
  success_count <- 0L
  fail_count <- 0L

  for (i in seq_along(dates)) {
    date_val <- dates[i]
    message(sprintf("  [%s] Fetching options date %d/%d: %s",
                    ticker, i, length(dates), format(date_val)))

    result <- tryCatch({
      fetch_historical_options(ticker, date_val, api_key = api_key)
    }, error = function(e) {
      message(sprintf("    WARN: %s", conditionMessage(e)))
      NULL
    })

    if (!is.null(result) && nrow(result) > 0) {
      fetched_data[[length(fetched_data) + 1]] <- result
      success_count <- success_count + 1L
    } else {
      fail_count <- fail_count + 1L
    }
  }

  if (length(fetched_data) == 0) {
    return(list(success_count = success_count, fail_count = fail_count, total_rows = 0L))
  }

  new_data <- dplyr::bind_rows(fetched_data)

  # Read existing data from S3 and append
  existing <- tryCatch(
    s3_read_ticker_raw_data_single(ticker, "historical_options", bucket_name, region),
    error = function(e) NULL
  )

  if (!is.null(existing) && nrow(existing) > 0) {
    combined <- dplyr::bind_rows(existing, new_data) %>%
      dplyr::distinct(contractID, date, .keep_all = TRUE) %>%
      dplyr::arrange(date, expiration, strike, type)
  } else {
    combined <- new_data %>%
      dplyr::arrange(date, expiration, strike, type)
  }

  # Write back to S3
  s3_write_ticker_raw_data(combined, ticker, "historical_options", bucket_name, region)

  list(
    success_count = success_count,
    fail_count = fail_count,
    total_rows = nrow(combined)
  )
}
