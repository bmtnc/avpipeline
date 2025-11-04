#' Select Essential Columns
#'
#' Selects only essential columns from unified financial dataset including date
#' columns, meta columns, and all per-share metrics.
#'
#' @param data data.frame: Dataset with financial and price data
#' @return data.frame: Dataset with only essential columns
#' @keywords internal
select_essential_columns <- function(data) {
  if (!is.data.frame(data)) {
    stop(paste0("select_essential_columns(): [data] must be a data.frame, not ", class(data)[1]))
  }

  date_cols <- c(
    "date",
    "fiscalDateEnding",
    "reportedDate",
    "calendar_quarter_ending"
  )

  meta_cols <- c(
    "ticker",
    "open",
    "high",
    "low",
    "adjusted_close",
    "volume",
    "dividend_amount",
    "split_coefficient",
    "n",
    "post_filing_split_multiplier",
    "effective_shares_outstanding",
    "commonStockSharesOutstanding",
    "market_cap"
  )

  data %>%
    dplyr::select(
      dplyr::any_of(date_cols),
      dplyr::any_of(meta_cols),
      dplyr::contains("per_share")
    )
}
