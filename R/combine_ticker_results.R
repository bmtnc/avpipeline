#' Combine Ticker Results
#'
#' Combines results from multiple tickers into a single dataframe with proper
#' column ordering and metadata. This function replaces all individual result
#' combination functions by using configuration objects to determine the
#' appropriate sorting and formatting.
#'
#' @param results_list List of tibbles with data (may contain NULL entries)
#' @param tickers Character vector. Original vector of equity symbols
#' @param config List. Configuration object defining the data type and sorting parameters
#'
#' @return A tibble with combined data for all successful tickers
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' # Combine price data results
#' combined_data <- combine_ticker_results(results_list, tickers, PRICE_CONFIG)
#' 
#' # Combine income statement results
#' combined_data <- combine_ticker_results(results_list, tickers, INCOME_STATEMENT_CONFIG)
#' }
combine_ticker_results <- function(results_list, tickers, config) {
  
  # Validate inputs
  if (missing(results_list) || !is.list(results_list)) {
    stop("results_list must be a list")
  }
  
  if (missing(tickers) || !is.character(tickers)) {
    stop("tickers must be a character vector")
  }
  
  if (missing(config) || !is.list(config)) {
    stop("config must be a configuration list object")
  }
  
  if (!"data_type_name" %in% names(config)) {
    stop("config must contain a 'data_type_name' element")
  }
  
  if (!"result_sort_columns" %in% names(config)) {
    stop("config must contain a 'result_sort_columns' element")
  }
  
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
  
  # Ensure proper column order and sorting
  if (nrow(combined_df) > 0) {
    sort_columns <- config$result_sort_columns
    
    # Ensure ticker column is first
    if ("ticker" %in% names(combined_df)) {
      combined_df <- combined_df %>%
        dplyr::select(ticker, dplyr::everything())
    }
    
    # Apply sorting based on config
    if (length(sort_columns) > 0) {
      # Check if we should sort in descending order for date columns
      if (config$sort_desc %||% FALSE) {
        # For financial statements, sort by ticker ASC, then date DESC
        if (length(sort_columns) == 2) {
          combined_df <- combined_df %>%
            dplyr::arrange(!!dplyr::sym(sort_columns[1]), dplyr::desc(!!dplyr::sym(sort_columns[2])))
        } else {
          combined_df <- combined_df %>%
            dplyr::arrange(dplyr::desc(!!dplyr::sym(sort_columns[1])))
        }
      } else {
        # For price data, sort by ticker ASC, then date ASC
        if (length(sort_columns) == 2) {
          combined_df <- combined_df %>%
            dplyr::arrange(!!dplyr::sym(sort_columns[1]), !!dplyr::sym(sort_columns[2]))
        } else {
          combined_df <- combined_df %>%
            dplyr::arrange(!!dplyr::sym(sort_columns[1]))
        }
      }
    }
  }
  
  # Provide summary information
  cat("Successfully fetched data for", length(results_list), "out of", length(tickers), "tickers\n")
  
  # Provide data type appropriate summary
  if (grepl("income|balance|cash", config$data_type_name, ignore.case = TRUE)) {
    cat("Total quarterly reports:", nrow(combined_df), "\n")
  } else {
    cat("Total rows:", nrow(combined_df), "\n")
  }
  
  return(combined_df)
}

# Utility function for default values
`%||%` <- function(x, y) if (is.null(x)) y else x
