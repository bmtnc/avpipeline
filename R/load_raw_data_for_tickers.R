#' Load Raw Data for Specific Tickers from Local Directory
#'
#' Reads parquet files from a local directory for a specified set of tickers.
#'
#' Note: Currently unused. Incremental Phase 2 uses `s3_load_all_raw_data()` +
#' filter instead, since the S3 sync cost is fixed regardless. Retained for
#' potential future use in targeted single-ticker reprocessing.
#'
#' @param local_dir character: Local directory containing ticker subdirectories
#' @param tickers character: Tickers to load data for
#' @param data_types character or NULL: Data types to load (default: all 7 types)
#' @return list: Named list with each data type as a tibble
#' @keywords internal
load_raw_data_for_tickers <- function(
    local_dir,
    tickers,
    data_types = NULL
) {

  validate_character_scalar(local_dir, name = "local_dir")

  if (!is.character(tickers)) {
    stop("load_raw_data_for_tickers(): [tickers] must be a character vector")
  }

  if (!is.null(data_types) && !is.character(data_types)) {
    stop("load_raw_data_for_tickers(): [data_types] must be a character vector or NULL")
  }

  if (is.null(data_types)) {
    data_types <- c(
      "balance_sheet", "income_statement", "cash_flow",
      "earnings", "price", "splits", "overview"
    )
  }

  if (length(tickers) == 0) {
    result <- list()
    for (dt in data_types) {
      result[[dt]] <- tibble::tibble()
    }
    return(result)
  }

  n_cores <- min(length(data_types), parallel::detectCores())

  results <- parallel::mclapply(data_types, function(dt) {
    file_paths <- file.path(local_dir, tickers, paste0(dt, ".parquet"))
    file_paths <- file_paths[file.exists(file_paths)]

    tryCatch({
      if (length(file_paths) == 0) {
        return(list(data = tibble::tibble(), type = dt))
      }

      dfs <- lapply(file_paths, function(path) {
        tryCatch(arrow::read_parquet(path), error = function(e) NULL)
      })
      dfs <- dfs[!sapply(dfs, is.null)]
      combined <- if (length(dfs) > 0) dplyr::bind_rows(dfs) else tibble::tibble()
      list(data = combined, type = dt)
    }, error = function(e) {
      list(data = tibble::tibble(), type = dt)
    })
  }, mc.cores = n_cores)

  result <- list()
  for (r in results) {
    result[[r$type]] <- r$data
  }
  result
}
