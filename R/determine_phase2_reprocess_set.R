#' Determine Phase 2 Reprocess Set
#'
#' Determines which tickers need reprocessing by comparing the Phase 1 manifest
#' against the previous artifact and current S3 tickers.
#'
#' @param manifest tibble or NULL: Phase 1 manifest (NULL triggers full reprocess)
#' @param previous_artifact_tickers character: Tickers in the previous quarterly artifact
#' @param s3_tickers character: Tickers currently in S3 raw data
#' @return list with reprocess_tickers, unchanged_tickers, dropped_tickers, reason
#' @keywords internal
determine_phase2_reprocess_set <- function(
    manifest,
    previous_artifact_tickers,
    s3_tickers
) {

  # No manifest → full reprocess
  if (is.null(manifest) || nrow(manifest) == 0) {
    return(list(
      reprocess_tickers = sort(s3_tickers),
      unchanged_tickers = character(0),
      dropped_tickers = character(0),
      reason = "no_manifest"
    ))
  }

  # No previous artifact → full reprocess
  if (length(previous_artifact_tickers) == 0) {
    return(list(
      reprocess_tickers = sort(s3_tickers),
      unchanged_tickers = character(0),
      dropped_tickers = character(0),
      reason = "no_previous_artifact"
    ))
  }

  if (!"ticker" %in% names(manifest)) {
    stop("determine_phase2_reprocess_set(): manifest must contain 'ticker' column")
  }

  manifest_tickers <- unique(manifest$ticker)

  # New tickers: in S3 but not in previous artifact
  new_tickers <- setdiff(s3_tickers, previous_artifact_tickers)

  # Reprocess: manifest UNION new, intersected with s3_tickers
  reprocess_tickers <- intersect(union(manifest_tickers, new_tickers), s3_tickers)

  # Unchanged: in previous artifact, still in S3, not being reprocessed
  unchanged_tickers <- setdiff(
    intersect(previous_artifact_tickers, s3_tickers),
    reprocess_tickers
  )

  # Dropped: in previous artifact but no longer in S3
  dropped_tickers <- setdiff(previous_artifact_tickers, s3_tickers)

  list(
    reprocess_tickers = sort(reprocess_tickers),
    unchanged_tickers = sort(unchanged_tickers),
    dropped_tickers = sort(dropped_tickers),
    reason = "incremental"
  )
}
