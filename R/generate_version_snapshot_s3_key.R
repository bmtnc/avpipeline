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
