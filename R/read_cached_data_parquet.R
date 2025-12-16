#' Read Cached Data from Parquet
#'
#' Reads cached data from a Parquet file. Unlike CSV files, Parquet preserves data types
#' automatically, so date columns maintain their proper Date type without manual conversion.
#' This function provides a consistent interface for reading cached Parquet data across
#' different data types in the pipeline.
#'
#' @param cache_file Path to the cache file (Parquet format, .parquet extension)
#' @return A data frame with properly formatted columns (data types preserved from Parquet)
#' @export
#' 
read_cached_data_parquet <- function(cache_file) {
  
  # Validate input
  validate_file_exists(cache_file, name = "cache_file")
  
  # Validate file extension
  if (tools::file_ext(cache_file) != "parquet") {
    stop("File must have .parquet extension. Got: ", tools::file_ext(cache_file))
  }
  
  # Check if arrow package is available
  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop("The 'arrow' package is required to read Parquet files. Please install it with: install.packages('arrow')")
  }
  
  # Read the Parquet file
  tryCatch({
    data <- arrow::read_parquet(cache_file)
    return(data)
  }, error = function(e) {
    stop("Failed to read Parquet file: ", cache_file, "\nError: ", e$message)
  })
}