#' Initialize Tracking from Existing S3 Data
#'
#' Scans existing raw data in S3 and creates tracking entries based on what exists.
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return tibble: Initialized tracking dataframe
#' @keywords internal
initialize_tracking_from_s3_data <- function(bucket_name, region = "us-east-1") {
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("initialize_tracking_from_s3_data(): [bucket_name] must be a character scalar")
  }

  tickers <- s3_list_existing_tickers(bucket_name, region)

  if (length(tickers) == 0) {
    return(create_empty_refresh_tracking())
  }

  tracking_rows <- lapply(tickers, function(ticker) {
    tryCatch({
      price_data <- s3_read_ticker_raw_data_single(ticker, "price", bucket_name, region)
      earnings_data <- s3_read_ticker_raw_data_single(ticker, "earnings", bucket_name, region)

      extract_tracking_from_ticker_data(ticker, price_data, earnings_data)
    }, error = function(e) {
      create_default_ticker_tracking(ticker)
    })
  })

  tracking <- dplyr::bind_rows(tracking_rows)

  tracking
}
