#' Check if Raw Data Exists for Ticker in S3
#'
#' Checks which raw data files exist for a ticker in S3.
#'
#' @param ticker character: Stock symbol
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical vector: Named vector indicating which data types exist
#' @keywords internal
s3_check_ticker_raw_data_exists <- function(
  ticker,
  bucket_name,
  region = "us-east-1"
) {
  if (!is.character(ticker) || length(ticker) != 1) {
    stop(
      "s3_check_ticker_raw_data_exists(): [ticker] must be a character scalar"
    )
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop(
      "s3_check_ticker_raw_data_exists(): [bucket_name] must be a character scalar"
    )
  }

  prefix <- paste0("raw/", ticker, "/")
  s3_uri <- paste0("s3://", bucket_name, "/", prefix)

  result <- system2(
    "aws",
    args = c("s3", "ls", s3_uri, "--region", region),
    stdout = TRUE,
    stderr = TRUE
  )

  data_types <- c(
    "balance_sheet",
    "income_statement",
    "cash_flow",
    "earnings",
    "price",
    "splits"
  )

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    exists_vec <- rep(FALSE, length(data_types))
    names(exists_vec) <- data_types
    return(exists_vec)
  }

  exists_vec <- vapply(
    data_types,
    function(dt) {
      any(grepl(paste0(dt, "\\.parquet"), result))
    },
    logical(1)
  )

  exists_vec
}
