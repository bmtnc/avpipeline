#' Get Tickers Needing Specific Data Types
#'
#' Returns lists of tickers that need price or quarterly data refreshed.
#'
#' @param tracking tibble: Refresh tracking dataframe
#' @param reference_date Date: Date to compare against (default: Sys.Date())
#' @return list: Lists of tickers needing price_full, price_compact, quarterly
#' @export
get_tickers_needing_data <- function(tracking, reference_date = Sys.Date()) {
  if (!is.data.frame(tracking)) {
    stop("get_tickers_needing_data(): [tracking] must be a data.frame")
  }

  if (nrow(tracking) == 0) {
    return(list(
      needs_price_full = character(),
      needs_price_compact = character(),
      needs_quarterly = character(),
      up_to_date = character()
    ))
  }

  summary <- get_data_status_summary(tracking, reference_date)

  needs_price_full <- summary$ticker[summary$needs_price_full %in% TRUE]
  needs_price_compact <- summary$ticker[
    !summary$needs_price_full %in% TRUE &
    (is.na(summary$price_days_stale) | summary$price_days_stale > 0)
  ]
  needs_quarterly <- summary$ticker[summary$needs_quarterly %in% TRUE]

  up_to_date <- summary$ticker[
    !summary$needs_price_full %in% TRUE &
    !summary$needs_quarterly %in% TRUE &
    summary$price_days_stale <= 7
  ]

  list(
    needs_price_full = needs_price_full,
    needs_price_compact = needs_price_compact,
    needs_quarterly = needs_quarterly,
    up_to_date = up_to_date
  )
}
