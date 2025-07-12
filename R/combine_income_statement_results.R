#' Combine Income Statement Results into a Single Dataframe
#'
#' Combines income statement data from multiple tickers into a single tibble
#' with proper column ordering and metadata.
#'
#' @param results_list List of tibbles with income statement data (may contain NULL entries)
#' @param tickers Character vector. Original vector of equity symbols
#'
#' @return A tibble with combined quarterly income statement data for all successful tickers
#' @keywords internal
combine_income_statement_results <- function(results_list, tickers) {
  # Check if we have any results
  if (length(results_list) == 0) {
    stop("No data successfully fetched for any ticker")
  }
  
  # Remove NULL entries (failed fetches)
  results_list <- results_list[!sapply(results_list, is.null)]
  
  # Check again after removing NULLs
  if (length(results_list) == 0) {
    stop("No data successfully fetched for any ticker")
  }
  
  # Combine into single dataframe
  combined_df <- dplyr::bind_rows(results_list)
  
  # Ensure proper column order with ticker and fiscalDateEnding first
  if (nrow(combined_df) > 0) {
    combined_df <- combined_df %>%
      dplyr::select(ticker, fiscalDateEnding, dplyr::everything()) %>%
      dplyr::arrange(ticker, dplyr::desc(fiscalDateEnding))
  }
  
  # Provide summary information
  cat("Successfully fetched data for", length(results_list), "out of", length(tickers), "tickers\n")
  cat("Total quarterly reports:", nrow(combined_df), "\n")
  
  return(combined_df)
}
