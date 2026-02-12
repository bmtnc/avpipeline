#' Derive Phase 1 Manifest from Pipeline Log
#'
#' Extracts unique tickers and their updated data types from the pipeline log.
#'
#' @param pipeline_log tibble: Pipeline log with columns ticker, status, data_type, timestamp
#' @return tibble: Manifest with columns ticker, data_types_updated, timestamp
#' @keywords internal
derive_phase1_manifest <- function(pipeline_log) {

  validate_df_type(pipeline_log)

  empty_manifest <- tibble::tibble(
    ticker = character(),
    data_types_updated = character(),
    timestamp = as.POSIXct(character())
  )

  if (nrow(pipeline_log) == 0) {
    return(empty_manifest)
  }

  success_log <- dplyr::filter(pipeline_log, status == "success")

  if (nrow(success_log) == 0) {
    return(empty_manifest)
  }

  success_log |>
    dplyr::group_by(ticker) |>
    dplyr::summarise(
      data_types_updated = paste(sort(unique(data_type)), collapse = ","),
      timestamp = max(timestamp),
      .groups = "drop"
    )
}
