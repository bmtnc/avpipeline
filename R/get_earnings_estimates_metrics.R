#' Get Earnings Estimates Metric Names
#'
#' Returns the column names for earnings estimates data.
#'
#' @return character vector of earnings estimates metric names
#' @keywords internal
#' @export
get_earnings_estimates_metrics <- function() {
  c(
    "eps_estimate_average",
    "eps_estimate_high",
    "eps_estimate_low",
    "eps_estimate_analyst_count",
    "eps_estimate_average_7_days_ago",
    "eps_estimate_average_30_days_ago",
    "eps_estimate_average_60_days_ago",
    "eps_estimate_average_90_days_ago",
    "eps_estimate_revision_up_trailing_7_days",
    "eps_estimate_revision_down_trailing_7_days",
    "eps_estimate_revision_up_trailing_30_days",
    "eps_estimate_revision_down_trailing_30_days",
    "revenue_estimate_average",
    "revenue_estimate_high",
    "revenue_estimate_low",
    "revenue_estimate_analyst_count"
  )
}
