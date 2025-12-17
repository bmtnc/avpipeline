#' List Existing Tickers in S3 Raw Data
#'
#' Returns a vector of ticker symbols that have data stored in S3.
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return character: Vector of ticker symbols found in S3
#' @keywords internal
s3_list_existing_tickers <- function(bucket_name, region = "us-east-1") {
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop("s3_list_existing_tickers(): [bucket_name] must be a character scalar")
  }

  s3_prefix <- paste0("s3://", bucket_name, "/raw/")

  result <- system2_with_timeout(
    "aws",
    args = c("s3", "ls", s3_prefix, "--region", region),
    timeout_seconds = 60,
    stdout = TRUE,
    stderr = TRUE
  )

  if (is_timeout_result(result) ||
      (!is.null(attr(result, "status")) && attr(result, "status") != 0)) {
    return(character(0))
  }

  if (length(result) == 0) {
    return(character(0))
  }

  prefixes <- result[grepl("PRE ", result)]

  if (length(prefixes) == 0) {
    return(character(0))
  }

  tickers <- gsub("^\\s*PRE\\s+", "", prefixes)
  tickers <- gsub("/$", "", tickers)

  tickers <- tickers[tickers != "_metadata"]

  sort(tickers)
}
