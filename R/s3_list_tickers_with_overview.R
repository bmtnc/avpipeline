#' List Tickers That Already Have Overview Data in S3
#'
#' Returns the tickers whose `raw/{TICKER}/overview.parquet` already exists, so
#' Phase 1 can gap-fill overview only for tickers that are missing it (overview
#' rarely changes, so it is fetched once and never re-pulled).
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return character: Vector of ticker symbols that have an overview parquet
#' @keywords internal
s3_list_tickers_with_overview <- function(bucket_name, region = "us-east-1") {
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("s3_list_tickers_with_overview(): [bucket_name] must be a character scalar")
  }

  s3_prefix <- paste0("s3://", bucket_name, "/raw/")

  result <- system2_with_timeout(
    "aws",
    args = c("s3", "ls", s3_prefix, "--recursive", "--region", region),
    timeout_seconds = 120,
    stdout = TRUE,
    stderr = TRUE
  )

  if (is_timeout_result(result) ||
      (!is.null(attr(result, "status")) && attr(result, "status") != 0) ||
      length(result) == 0) {
    return(character(0))
  }

  overview_lines <- result[grepl("/overview\\.parquet$", result)]

  if (length(overview_lines) == 0) {
    return(character(0))
  }

  tickers <- sub(".*raw/(.+)/overview\\.parquet$", "\\1", overview_lines)

  sort(unique(tickers))
}
