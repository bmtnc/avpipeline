#' Build Phase 2 Pipeline Log from Worker Results
#'
#' Assembles the per-ticker pipeline log from the records returned by the
#' Phase 2 parallel workers.
#'
#' Phase 2 processes tickers under `parallel::mclapply`, which forks. A forked
#' worker cannot append to a shared log — its mutations die with the fork — so
#' each worker returns its own outcome record and the parent assembles them
#' here. This is why Phase 2 cannot reuse the sequential `add_log_entry()`
#' accumulation that Phase 1's serial ticker loop relies on.
#'
#' @param results list: Per-ticker records from the Phase 2 worker
#' @param tickers character: Tickers processed, positionally matching results
#' @param data_type character: Log data_type label (default: "quarterly")
#' @return tibble: Pipeline log with one row per ticker
#' @keywords internal
build_phase2_log <- function(results, tickers, data_type = "quarterly") {
  if (!is.list(results)) {
    stop(paste0(
      "build_phase2_log(): [results] must be a list. Received: ",
      class(results)[1]
    ))
  }
  validate_character_scalar(data_type, name = "build_phase2_log(): [data_type]")

  if (length(results) != length(tickers)) {
    stop(sprintf(
      paste0(
        "build_phase2_log(): [results] (%d) and [tickers] (%d) ",
        "must be the same length"
      ),
      length(results),
      length(tickers)
    ))
  }

  if (length(results) == 0) {
    return(create_pipeline_log())
  }

  dplyr::bind_rows(lapply(
    seq_along(results),
    function(i) normalize_phase2_result(results[[i]], tickers[[i]], data_type)
  ))
}
