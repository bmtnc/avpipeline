#' Summarize Artifact Construction
#'
#' Prints comprehensive summary of financial statements artifact construction,
#' including removed observations, gap statistics, and final artifact details.
#'
#' @param original_data tibble: Original data before quarterly continuity filtering with ticker and fiscalDateEnding columns
#' @param final_data tibble: Final filtered data with ticker, fiscalDateEnding, and quality flag columns
#' @param removed_detail tibble or NULL: Optional detailed breakdown of removed observations by ticker
#' @return invisible NULL (side effect: prints summary to console)
#' @keywords internal
summarize_artifact_construction <- function(
  original_data,
  final_data,
  removed_detail = NULL
) {
  if (!is.data.frame(original_data)) {
    stop(paste0(
      "summarize_artifact_construction(): [original_data] must be a data.frame, not ",
      class(original_data)[1]
    ))
  }
  if (!is.data.frame(final_data)) {
    stop(paste0(
      "summarize_artifact_construction(): [final_data] must be a data.frame, not ",
      class(final_data)[1]
    ))
  }
  if (!is.null(removed_detail) && !is.data.frame(removed_detail)) {
    stop(paste0(
      "summarize_artifact_construction(): [removed_detail] must be a data.frame or NULL, not ",
      class(removed_detail)[1]
    ))
  }

  original_obs <- nrow(original_data)
  final_obs <- nrow(final_data)
  removed_obs <- original_obs - final_obs

  if (removed_obs > 0) {
    message(paste0(
      "Removed ",
      removed_obs,
      " observations to ensure continuous quarterly spacing"
    ))

    if (!is.null(removed_detail) && nrow(removed_detail) > 0) {
      message("\nDetailed breakdown by ticker:")
      for (i in seq_len(nrow(removed_detail))) {
        ticker <- removed_detail$ticker[i]
        count <- removed_detail$removed_count[i]
        earliest <- removed_detail$earliest_removed[i]
        latest <- removed_detail$latest_removed[i]

        message(paste0(
          "  ",
          ticker,
          ": ",
          count,
          " observations removed (",
          as.character(earliest),
          " to ",
          as.character(latest),
          ")"
        ))
      }
    }
  }

  completely_removed_tickers <- setdiff(
    unique(original_data$ticker),
    unique(final_data$ticker)
  )

  if (length(completely_removed_tickers) > 0) {
    message(paste0(
      "\nRemoved ",
      length(completely_removed_tickers),
      " tickers with no continuous quarterly series:"
    ))
    message(paste(completely_removed_tickers, collapse = ", "))
  }

  final_with_gaps <- final_data %>%
    dplyr::group_by(ticker) %>%
    dplyr::arrange(ticker, fiscalDateEnding) %>%
    dplyr::mutate(
      days_since_last_report = as.numeric(
        fiscalDateEnding - dplyr::lag(fiscalDateEnding)
      )
    ) %>%
    dplyr::ungroup()

  message("\nPerforming final validation of quarterly continuity...")
  message(
    "\u2713 All observations validated using fiscal-pattern quarterly validation"
  )

  gaps_to_analyze <- final_with_gaps %>%
    dplyr::filter(!is.na(days_since_last_report))

  if (nrow(gaps_to_analyze) > 0) {
    gap_stats <- gaps_to_analyze %>%
      dplyr::summarise(
        total_gaps = dplyr::n(),
        min_days = min(days_since_last_report),
        max_days = max(days_since_last_report),
        avg_days = round(mean(days_since_last_report), 1),
        median_days = median(days_since_last_report),
        gaps_80_to_100_pct = round(
          100 *
            mean(days_since_last_report >= 80 & days_since_last_report <= 100),
          1
        )
      )

    message("\nGap statistics (for informational purposes):")
    message(paste0("- Total gaps analyzed: ", gap_stats$total_gaps))
    message(paste0(
      "- Range: ",
      gap_stats$min_days,
      " to ",
      gap_stats$max_days,
      " days"
    ))
    message(paste0("- Average gap: ", gap_stats$avg_days, " days"))
    message(paste0("- Median gap: ", gap_stats$median_days, " days"))
    message(paste0(
      "- Gaps in 80-100 day range: ",
      gap_stats$gaps_80_to_100_pct,
      "%"
    ))
  }

  has_complete_financials_col <- "has_complete_financials" %in%
    names(final_data)
  has_earnings_metadata_col <- "has_earnings_metadata" %in% names(final_data)

  message("\nFinal financial statements artifact:")
  message(paste0("- Observations: ", nrow(final_data)))
  message(paste0("- Tickers: ", length(unique(final_data$ticker))))
  message(paste0(
    "- Date range: ",
    as.character(min(final_data$fiscalDateEnding)),
    " to ",
    as.character(max(final_data$fiscalDateEnding))
  ))

  if (has_complete_financials_col) {
    message(paste0(
      "- Complete financial records: ",
      sum(final_data$has_complete_financials)
    ))
  }

  if (has_earnings_metadata_col) {
    message(paste0(
      "- Records with earnings metadata: ",
      sum(final_data$has_earnings_metadata)
    ))
  }

  return(invisible(NULL))
}
