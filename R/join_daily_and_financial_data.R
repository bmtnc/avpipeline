#' Join Daily and Financial Data
#'
#' Joins price data, market cap data, and TTM financial data on ticker and date.
#' Removes unnecessary columns from intermediate datasets.
#'
#' @param price_data tibble: Daily price data with ticker and date columns
#' @param market_cap_data tibble: Daily market cap data with ticker and date columns
#' @param ttm_data tibble: TTM financial data with ticker and date columns
#' @return tibble: Joined dataset with all financial metrics
#' @keywords internal
join_daily_and_financial_data <- function(
  price_data,
  market_cap_data,
  ttm_data
) {
  if (!is.data.frame(price_data)) {
    stop(paste0(
      "join_daily_and_financial_data(): [price_data] must be a data.frame, not ",
      class(price_data)[1]
    ))
  }
  if (!is.data.frame(market_cap_data)) {
    stop(paste0(
      "join_daily_and_financial_data(): [market_cap_data] must be a data.frame, not ",
      class(market_cap_data)[1]
    ))
  }
  if (!is.data.frame(ttm_data)) {
    stop(paste0(
      "join_daily_and_financial_data(): [ttm_data] must be a data.frame, not ",
      class(ttm_data)[1]
    ))
  }
  if (!all(c("ticker", "date") %in% names(price_data))) {
    stop(paste0(
      "join_daily_and_financial_data(): [price_data] must contain 'ticker' and 'date' columns"
    ))
  }
  if (!all(c("ticker", "date") %in% names(market_cap_data))) {
    stop(paste0(
      "join_daily_and_financial_data(): [market_cap_data] must contain 'ticker' and 'date' columns"
    ))
  }
  if (!all(c("ticker", "date") %in% names(ttm_data))) {
    stop(paste0(
      "join_daily_and_financial_data(): [ttm_data] must contain 'ticker' and 'date' columns"
    ))
  }

  price_clean <- price_data %>%
    dplyr::select(-dplyr::any_of("as_of_date"))

  market_cap_clean <- market_cap_data %>%
    dplyr::select(
      -dplyr::any_of(c(
        "as_of_date",
        "close",
        "commonStockSharesOutstanding",
        "has_financial_data",
        "days_since_financial_report",
        "reportedDate"
      ))
    )

  # Join datasets
  price_clean %>%
    dplyr::left_join(market_cap_clean, by = c("ticker", "date")) %>%
    dplyr::left_join(ttm_data, by = c("ticker", "date")) %>%
    dplyr::select(
      ticker,
      date,
      dplyr::contains("date"),
      dplyr::any_of("calendar_quarter_ending"),
      dplyr::everything()
    )
}
