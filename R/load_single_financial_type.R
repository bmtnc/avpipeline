#' Load Single Financial Data Type from Cache
#'
#' Loads financial data for a specific data type from its cache file.
#'
#' @param cache_path character: Path to cache file for this data type
#' @param config list: Configuration object (e.g., BALANCE_SHEET_CONFIG)
#' @return tibble: Loaded financial data
#' @keywords internal
load_single_financial_type <- function(cache_path, config) {
  if (!is.character(cache_path) || length(cache_path) != 1) {
    stop(paste0("load_single_financial_type(): [cache_path] must be a character scalar, not ", class(cache_path)[1], " of length ", length(cache_path)))
  }
  
  if (!is.list(config)) {
    stop(paste0("load_single_financial_type(): [config] must be a list, not ", class(config)[1]))
  }
  
  data <- read_cached_data_parquet(cache_path)
  message(paste0(config$data_type_name, " data loaded: ", nrow(data), " rows"))
  
  data
}
