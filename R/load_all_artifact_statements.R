#' Load All Artifact Statements
#'
#' Orchestrates loading of all 4 financial statement artifacts from cache files.
#'
#' @return list: Named list with earnings, cash_flow, income_statement, balance_sheet
#' @keywords internal
load_all_artifact_statements <- function() {
  cache_paths <- c(
    earnings = "cache/earnings_artifact.parquet",
    cash_flow = "cache/cash_flow_artifact.parquet",
    income_statement = "cache/income_statement_artifact.parquet",
    balance_sheet = "cache/balance_sheet_artifact.parquet"
  )

  validate_artifact_files(cache_paths)

  earnings <- read_cached_data_parquet(cache_paths["earnings"])
  cash_flow <- read_cached_data_parquet(cache_paths["cash_flow"])
  income_statement <- read_cached_data_parquet(cache_paths["income_statement"])
  balance_sheet <- read_cached_data_parquet(cache_paths["balance_sheet"])

  list(
    earnings = earnings,
    cash_flow = cash_flow,
    income_statement = income_statement,
    balance_sheet = balance_sheet
  )
}
