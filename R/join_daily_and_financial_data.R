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
  validate_df_cols(price_data, c("ticker", "date"))
  validate_df_cols(market_cap_data, c("ticker", "date"))
  validate_df_cols(ttm_data, c("ticker", "date"))

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
