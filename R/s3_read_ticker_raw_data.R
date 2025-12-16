#' Read All Raw Data for a Ticker from S3
#'
#' Downloads all 6 raw data parquet files for a ticker from S3.
#'
#' @param ticker character: Stock symbol
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return list: Named list with balance_sheet, income_statement, cash_flow, earnings, price, splits (NULL for missing)
#' @keywords internal
s3_read_ticker_raw_data <- function(ticker, bucket_name, region = "us-east-1") {
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("s3_read_ticker_raw_data(): [ticker] must be a character scalar")
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("s3_read_ticker_raw_data(): [bucket_name] must be a character scalar")
  }

  data_types <- c(
    "balance_sheet",
    "income_statement",
    "cash_flow",
    "earnings",
    "price",
    "splits"
  )

  result <- lapply(data_types, function(dt) {
    s3_read_ticker_raw_data_single(ticker, dt, bucket_name, region)
  })
  names(result) <- data_types

  result
}
