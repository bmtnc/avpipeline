#' Load All Raw Data from S3 Using Arrow Datasets
#'
#' Loads all data types for all tickers using Arrow's S3 reading with
#' parallel loading across data types.
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

  # Load all data types in parallel
  n_cores <- min(length(data_types), parallel::detectCores())
  log_pipeline(sprintf("Loading %d data types in parallel using %d cores...",
                       length(data_types), n_cores))
  load_start <- Sys.time()

  results <- parallel::mclapply(data_types, function(dt) {
    start_time <- Sys.time()

    # Build list of S3 URIs for this data type
    file_uris <- paste0(
      "s3://", bucket_name, "/raw/", tickers, "/", dt, ".parquet",
      "?region=", region
    )

    # Read files - use open_dataset for efficiency when possible
    tryCatch({
      # For many files, read in chunks to balance memory and speed
      chunk_size <- 500
      n_chunks <- ceiling(length(file_uris) / chunk_size)

      chunk_results <- lapply(seq_len(n_chunks), function(i) {
        start_idx <- (i - 1) * chunk_size + 1
        end_idx <- min(i * chunk_size, length(file_uris))
        chunk_uris <- file_uris[start_idx:end_idx]

        dfs <- lapply(chunk_uris, function(uri) {
          tryCatch(arrow::read_parquet(uri), error = function(e) NULL)
        })
        dfs <- dfs[!sapply(dfs, is.null)]
        if (length(dfs) > 0) dplyr::bind_rows(dfs) else NULL
      })

      chunk_results <- chunk_results[!sapply(chunk_results, is.null)]
      combined <- dplyr::bind_rows(chunk_results)

      duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      list(data = combined, type = dt, rows = nrow(combined), duration = duration)
    }, error = function(e) {
      list(data = tibble::tibble(), type = dt, rows = 0,
           duration = 0, error = e$message)
    })
  }, mc.cores = n_cores)

  # Convert to named list and log results
  result <- list()
  for (r in results) {
    result[[r$type]] <- r$data
    if (!is.null(r$error)) {
      log_pipeline(sprintf("  %s: FAILED - %s", r$type, r$error))
    } else {
      log_pipeline(sprintf("  %s: %d rows in %.1fs", r$type, r$rows, r$duration))
    }
  }

  total_duration <- as.numeric(difftime(Sys.time(), load_start, units = "secs"))
  log_pipeline(sprintf("All data loaded in %.1f seconds", total_duration))

  result
}
