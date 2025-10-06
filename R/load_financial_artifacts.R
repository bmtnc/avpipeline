#' Load Financial Artifacts
#'
#' Loads financial statement, market cap, and price data from cached files
#' with proper date column handling.
#'
#' @return list: Named list with financial_statements, market_cap_data, and price_data
#' @keywords internal
load_financial_artifacts <- function() {
  # Define cache paths
  financial_path <- "cache/financial_statements_artifact.csv"
  market_cap_path <- "cache/market_cap_artifact_vectorized.csv"
  price_path <- "cache/price_artifact.csv"
  
  # Validate files exist
  if (!file.exists(financial_path)) {
    stop(paste0(
      "load_financial_artifacts(): Financial statements file not found at ",
      financial_path
    ))
  }
  
  if (!file.exists(market_cap_path)) {
    stop(paste0(
      "load_financial_artifacts(): Market cap file not found at ",
      market_cap_path
    ))
  }
  
  if (!file.exists(price_path)) {
    stop(paste0(
      "load_financial_artifacts(): Price file not found at ",
      price_path
    ))
  }
  
  # Load data with proper date column handling
  financial_statements <- read_cached_data(
    financial_path,
    date_columns = c(
      "fiscalDateEnding",
      "calendar_quarter_ending",
      "reportedDate",
      "as_of_date"
    )
  )
  
  market_cap_data <- read_cached_data(
    market_cap_path,
    date_columns = c("date", "reportedDate", "as_of_date")
  )
  
  price_data <- read_cached_data(
    price_path,
    date_columns = c("date", "as_of_date")
  )
  
  list(
    financial_statements = financial_statements,
    market_cap_data = market_cap_data,
    price_data = price_data
  )
}
