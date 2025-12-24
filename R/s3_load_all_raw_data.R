#' Load All Raw Data from S3 Using Arrow Datasets
#'
#' Loads all data types for all tickers using Arrow's efficient S3 reading.
#' Lists all ticker folders first, then reads all files of each type in one call.
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return list: Named list with all data types as tibbles
#' @keywords internal
s3_load_all_raw_data <- function(bucket_name, region = "us-east-1") {
  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(region, name = "region")

  # Get list of all tickers
  log_pipeline("Listing tickers in S3...")
  tickers <- s3_list_existing_tickers(bucket_name, region)
  log_pipeline(sprintf("Found %d tickers", length(tickers)))

  data_types <- c(
    "balance_sheet",
    "income_statement",
    "cash_flow",
    "earnings",
    "price",
    "splits",
    "overview"
  )

  result <- list()

  for (dt in data_types) {
    log_pipeline(sprintf("Loading %s data...", dt))
    start_time <- Sys.time()

    # Build list of S3 URIs for this data type
    file_uris <- paste0(
      "s3://", bucket_name, "/raw/", tickers, "/", dt, ".parquet",
      "?region=", region
    )

    # Read all files in parallel using Arrow
    tryCatch({
      # Read each file and combine - Arrow handles parallelism internally
      dfs <- lapply(file_uris, function(uri) {
        tryCatch(
          arrow::read_parquet(uri),
          error = function(e) NULL
        )
      })

      # Remove NULLs and combine
      dfs <- dfs[!sapply(dfs, is.null)]
      result[[dt]] <- dplyr::bind_rows(dfs)

      duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      log_pipeline(sprintf("  Loaded %s: %d rows in %.1fs",
                           dt, nrow(result[[dt]]), duration))
    }, error = function(e) {
      warning(sprintf("Failed to load %s: %s", dt, e$message))
      result[[dt]] <<- tibble::tibble()
    })
  }

  result
}
