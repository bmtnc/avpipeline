#' Load All Raw Data from S3
#'
#' Syncs all raw data from S3 to local disk, then reads parquet files locally.
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @return list: Named list with all data types as tibbles
#' @keywords internal
s3_load_all_raw_data <- function(bucket_name, region = "us-east-1") {

  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(region, name = "region")

  # Sync raw data from S3 to local temp directory
  local_dir <- tempfile(pattern = "raw_data_")
  dir.create(local_dir, recursive = TRUE)
  on.exit(unlink(local_dir, recursive = TRUE), add = TRUE)

  log_pipeline("Syncing raw data from S3 to local disk...")
  sync_start <- Sys.time()

  sync_result <- system2_with_timeout(
    "aws",
    args = c("s3", "sync",
             paste0("s3://", bucket_name, "/raw/"), local_dir,
             "--region", region,
             "--exclude", "*/_versions/*",
             "--exclude", "_metadata/*",
             "--only-show-errors"),
    timeout_seconds = 600,
    stdout = TRUE,
    stderr = TRUE
  )

  if (is_timeout_result(sync_result)) {
    stop("S3 sync timed out after 600 seconds")
  }
  if (!is.null(attr(sync_result, "status")) && attr(sync_result, "status") != 0) {
    stop("S3 sync failed: ", paste(sync_result, collapse = "\n"))
  }

  sync_duration <- as.numeric(difftime(Sys.time(), sync_start, units = "secs"))
  log_pipeline(sprintf("S3 sync completed in %.1f seconds", sync_duration))

  # Discover tickers from local directories
  tickers <- list.dirs(local_dir, recursive = FALSE, full.names = FALSE)
  tickers <- setdiff(tickers, "_metadata")
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

  # Load all data types in parallel from local disk
  n_cores <- min(length(data_types), parallel::detectCores())
  log_pipeline(sprintf("Loading %d data types in parallel using %d cores...",
                       length(data_types), n_cores))
  load_start <- Sys.time()

  results <- parallel::mclapply(data_types, function(dt) {
    start_time <- Sys.time()

    file_paths <- file.path(local_dir, tickers, paste0(dt, ".parquet"))
    file_paths <- file_paths[file.exists(file_paths)]

    tryCatch({
      if (length(file_paths) == 0) {
        return(list(data = tibble::tibble(), type = dt, rows = 0, duration = 0))
      }

      dfs <- lapply(file_paths, function(path) {
        tryCatch(arrow::read_parquet(path), error = function(e) NULL)
      })
      dfs <- dfs[!sapply(dfs, is.null)]
      combined <- if (length(dfs) > 0) dplyr::bind_rows(dfs) else tibble::tibble()

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
