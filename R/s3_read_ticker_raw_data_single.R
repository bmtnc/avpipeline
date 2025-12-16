#' Read Single Ticker Raw Data from S3
#'
#' Downloads a single data type parquet file for a ticker from S3.
#'
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data (e.g., "balance_sheet", "price")
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return data.frame or NULL if file doesn't exist
#' @keywords internal
s3_read_ticker_raw_data_single <- function(
  ticker,
  data_type,
  bucket_name,
  region = "us-east-1"
) {
  if (!is.character(ticker) || length(ticker) != 1) {
    stop(
      "s3_read_ticker_raw_data_single(): [ticker] must be a character scalar"
    )
  }
  if (!is.character(data_type) || length(data_type) != 1) {
    stop(
      "s3_read_ticker_raw_data_single(): [data_type] must be a character scalar"
    )
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop(
      "s3_read_ticker_raw_data_single(): [bucket_name] must be a character scalar"
    )
  }

  s3_key <- generate_raw_data_s3_key(ticker, data_type)
  s3_uri <- paste0("s3://", bucket_name, "/", s3_key)

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  result <- system2(
    "aws",
    args = c("s3", "cp", s3_uri, temp_file, "--region", region),
    stdout = TRUE,
    stderr = TRUE
  )

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    return(NULL)
  }

  if (!file.exists(temp_file)) {
    return(NULL)
  }

  arrow::read_parquet(temp_file)
}
