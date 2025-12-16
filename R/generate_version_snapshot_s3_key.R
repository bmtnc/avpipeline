#' Generate S3 Key for Raw Data Version Snapshot
#'
#' Generates the S3 key path for a versioned snapshot of ticker data.
#'
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data (e.g., "balance_sheet", "price")
#' @param snapshot_date Date: Date of the snapshot (defaults to current date)
#' @return character: S3 key path in _versions/ folder
#' @keywords internal
generate_version_snapshot_s3_key <- function(
  ticker,
  data_type,
  snapshot_date = Sys.Date()
) {
  validate_character_scalar(ticker, allow_empty = FALSE, name = "ticker")
  validate_character_scalar(data_type, allow_empty = FALSE, name = "data_type")
  validate_date_type(snapshot_date, scalar = TRUE, name = "snapshot_date")

  date_string <- format(snapshot_date, "%Y-%m-%d")
  paste0("raw/", ticker, "/_versions/", data_type, "_", date_string, ".parquet")
}
