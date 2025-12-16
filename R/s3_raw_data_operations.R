#' Generate S3 Key for Raw Ticker Data
#'
#' Generates the S3 key path for a specific ticker and data type.
#'
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data (e.g., "balance_sheet", "price")
#' @return character: S3 key path
#' @keywords internal
generate_raw_data_s3_key <- function(ticker, data_type) {
  if (!is.character(ticker) || length(ticker) != 1 || nchar(ticker) == 0) {
    stop("generate_raw_data_s3_key(): [ticker] must be a non-empty character scalar")
  }
  if (!is.character(data_type) || length(data_type) != 1 || nchar(data_type) == 0) {
    stop("generate_raw_data_s3_key(): [data_type] must be a non-empty character scalar")
  }

  paste0("raw/", ticker, "/", data_type, ".parquet")
}

#' Generate S3 Key for Raw Data Version Snapshot
#'
#' Generates the S3 key path for a versioned snapshot of ticker data.
#'
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data (e.g., "balance_sheet", "price")
#' @param snapshot_date Date: Date of the snapshot (defaults to current date)
#' @return character: S3 key path in _versions/ folder
#' @keywords internal
generate_version_snapshot_s3_key <- function(ticker, data_type, snapshot_date = Sys.Date()) {
  if (!is.character(ticker) || length(ticker) != 1 || nchar(ticker) == 0) {
    stop("generate_version_snapshot_s3_key(): [ticker] must be a non-empty character scalar")
  }
  if (!is.character(data_type) || length(data_type) != 1 || nchar(data_type) == 0) {
    stop("generate_version_snapshot_s3_key(): [data_type] must be a non-empty character scalar")
  }
  if (!inherits(snapshot_date, "Date")) {
    stop("generate_version_snapshot_s3_key(): [snapshot_date] must be a Date object")
  }

  date_string <- format(snapshot_date, "%Y-%m-%d")
  paste0("raw/", ticker, "/_versions/", data_type, "_", date_string, ".parquet")
}

#' Write Single Ticker Raw Data to S3
#'
#' Uploads a single data type parquet file for a ticker to S3.
#'
#' @param data data.frame: Data to upload
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data (e.g., "balance_sheet", "price")
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if upload successful
#' @keywords internal
s3_write_ticker_raw_data <- function(data, ticker, data_type, bucket_name, region = "us-east-1") {
  if (!is.data.frame(data)) {
    stop("s3_write_ticker_raw_data(): [data] must be a data.frame")
  }
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("s3_write_ticker_raw_data(): [ticker] must be a character scalar")
  }
  if (!is.character(data_type) || length(data_type) != 1) {
    stop("s3_write_ticker_raw_data(): [data_type] must be a character scalar")
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("s3_write_ticker_raw_data(): [bucket_name] must be a character scalar")
  }

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  arrow::write_parquet(data, temp_file)

  s3_key <- generate_raw_data_s3_key(ticker, data_type)
  upload_artifact_to_s3(temp_file, bucket_name, s3_key, region)
}

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
s3_read_ticker_raw_data_single <- function(ticker, data_type, bucket_name, region = "us-east-1") {
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("s3_read_ticker_raw_data_single(): [ticker] must be a character scalar")
  }
  if (!is.character(data_type) || length(data_type) != 1) {
    stop("s3_read_ticker_raw_data_single(): [data_type] must be a character scalar")
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("s3_read_ticker_raw_data_single(): [bucket_name] must be a character scalar")
  }

  s3_key <- generate_raw_data_s3_key(ticker, data_type)
  s3_uri <- paste0("s3://", bucket_name, "/", s3_key)

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  result <- system2("aws",
                    args = c("s3", "cp", s3_uri, temp_file, "--region", region),
                    stdout = TRUE,
                    stderr = TRUE)

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    return(NULL)
  }

  if (!file.exists(temp_file)) {
    return(NULL)
  }

  arrow::read_parquet(temp_file)
}

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

  data_types <- c("balance_sheet", "income_statement", "cash_flow", "earnings", "price", "splits")

  result <- lapply(data_types, function(dt) {
    s3_read_ticker_raw_data_single(ticker, dt, bucket_name, region)
  })
  names(result) <- data_types

  result
}

#' Check if Raw Data Exists for Ticker in S3
#'
#' Checks which raw data files exist for a ticker in S3.
#'
#' @param ticker character: Stock symbol
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical vector: Named vector indicating which data types exist
#' @keywords internal
s3_check_ticker_raw_data_exists <- function(ticker, bucket_name, region = "us-east-1") {
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("s3_check_ticker_raw_data_exists(): [ticker] must be a character scalar")
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("s3_check_ticker_raw_data_exists(): [bucket_name] must be a character scalar")
  }

  prefix <- paste0("raw/", ticker, "/")
  s3_uri <- paste0("s3://", bucket_name, "/", prefix)

  result <- system2("aws",
                    args = c("s3", "ls", s3_uri, "--region", region),
                    stdout = TRUE,
                    stderr = TRUE)

  data_types <- c("balance_sheet", "income_statement", "cash_flow", "earnings", "price", "splits")

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    exists_vec <- rep(FALSE, length(data_types))
    names(exists_vec) <- data_types
    return(exists_vec)
  }

  exists_vec <- vapply(data_types, function(dt) {
    any(grepl(paste0(dt, "\\.parquet"), result))
  }, logical(1))

  exists_vec
}

#' Write Version Snapshot to S3
#'
#' Creates a timestamped backup of existing data before overwriting.
#'
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if snapshot created, FALSE if no existing data
#' @keywords internal
s3_write_version_snapshot <- function(ticker, data_type, bucket_name, region = "us-east-1") {
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("s3_write_version_snapshot(): [ticker] must be a character scalar")
  }
  if (!is.character(data_type) || length(data_type) != 1) {
    stop("s3_write_version_snapshot(): [data_type] must be a character scalar")
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("s3_write_version_snapshot(): [bucket_name] must be a character scalar")
  }

  existing_data <- s3_read_ticker_raw_data_single(ticker, data_type, bucket_name, region)

  if (is.null(existing_data)) {
    return(FALSE)
  }

  temp_file <- tempfile(fileext = ".parquet")
  on.exit(unlink(temp_file), add = TRUE)

  arrow::write_parquet(existing_data, temp_file)

  version_key <- generate_version_snapshot_s3_key(ticker, data_type, Sys.Date())
  upload_artifact_to_s3(temp_file, bucket_name, version_key, region)

  TRUE
}
