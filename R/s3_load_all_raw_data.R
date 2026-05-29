#' Load All Raw Data from S3
#'
#' Syncs all raw data from S3 to local disk, then reads parquet files locally.
#'
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region (default: "us-east-1")
#' @param data_types character: Subset of data types to load (default: NULL = all).
#'   When given, only those types are synced and read (e.g. "price").
#' @return list: Named list with the loaded data types as tibbles
#' @keywords internal
s3_load_all_raw_data <- function(bucket_name, region = "us-east-1",
                                 data_types = NULL) {

  validate_character_scalar(bucket_name, name = "bucket_name")
  validate_character_scalar(region, name = "region")

  all_data_types <- c(
    "balance_sheet", "income_statement", "cash_flow",
    "earnings", "price", "splits", "overview"
  )
  if (!is.null(data_types)) {
    invalid <- setdiff(data_types, all_data_types)
    if (length(invalid) > 0) {
      stop("s3_load_all_raw_data(): unknown data_types: ",
           paste(invalid, collapse = ", "))
    }
  }
  types_to_load <- data_types %||% all_data_types

  # Sync raw data from S3 to local temp directory
  local_dir <- tempfile(pattern = "raw_data_")
  dir.create(local_dir, recursive = TRUE)
  on.exit(unlink(local_dir, recursive = TRUE), add = TRUE)

  # Sync only the requested types when a subset is given (skips the rest).
  sync_filter <- if (is.null(data_types)) {
    c("--exclude", "*/_versions/*", "--exclude", "_metadata/*")
  } else {
    c("--exclude", "*",
      unlist(lapply(types_to_load,
                    function(dt) c("--include", paste0("*/", dt, ".parquet")))))
  }

  log_pipeline("Syncing raw data from S3 to local disk...")
  sync_start <- Sys.time()

  sync_result <- system2_with_timeout(
    "aws",
    args = c("s3", "sync",
             paste0("s3://", bucket_name, "/raw/"), local_dir,
             "--region", region,
             sync_filter,
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

  # Load the requested data types in parallel from local disk
  n_cores <- min(length(types_to_load), parallel::detectCores())
  log_pipeline(sprintf("Loading %d data types in parallel using %d cores...",
                       length(types_to_load), n_cores))
  load_start <- Sys.time()

  results <- parallel::mclapply(types_to_load, function(dt) {
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
