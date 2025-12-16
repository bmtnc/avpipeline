#' Build Daily Market Cap with Split Adjustments
#'
#' Constructs daily market capitalization by combining price data, financial
#' statements (shares outstanding), and stock splits. Adjusts shares outstanding
#' for post-filing splits to ensure accurate market cap calculation.
#'
#' @param price_data tibble: Daily price data with columns ticker, date, close
#' @param splits_data tibble: Stock split data with columns ticker, effective_date, split_factor
#' @param financial_statements tibble: Financial statements with commonStockSharesOutstanding and reportedDate
#' @param start_date Date: Start date for filtering data
#' @return tibble: Daily market cap with split-adjusted shares and market cap in millions
#' @keywords internal
build_market_cap_with_splits <- function(
  price_data,
  splits_data,
  financial_statements,
  start_date
) {
  # Input validation
  if (!inherits(start_date, "Date") || length(start_date) != 1) {
    stop(paste0(
      "build_market_cap_with_splits(): [start_date] must be a Date scalar, not ",
      class(start_date)[1],
      " of length ",
      length(start_date)
    ))
  }

  # Clean splits data
  splits_clean <- splits_data %>%
    dplyr::mutate(split_factor = as.numeric(split_factor)) %>%
    dplyr::filter(!is.na(split_factor) & split_factor > 0) %>%
    dplyr::select(ticker, date = effective_date, split_factor) %>%
    dplyr::arrange(date)

  # Clean price data
  prices_clean <- price_data %>%
    dplyr::filter(
      date >= start_date,
      !is.na(close) & close > 0
    ) %>%
    dplyr::mutate(close = as.numeric(close)) %>%
    dplyr::select(ticker, date, close) %>%
    dplyr::distinct() %>%
    dplyr::arrange(date)

  # Clean financial data for market cap calculation
  financial_clean <- financial_statements %>%
    dplyr::filter(fiscalDateEnding >= start_date) %>%
    dplyr::mutate(
      commonStockSharesOutstanding = as.numeric(commonStockSharesOutstanding)
    ) %>%
    dplyr::filter(
      !is.na(commonStockSharesOutstanding) &
        commonStockSharesOutstanding > 0
    ) %>%
    dplyr::select(ticker, reportedDate, commonStockSharesOutstanding) %>%
    dplyr::arrange(reportedDate)

  # Build daily shares outstanding
  daily_shares <- prices_clean %>%
    dplyr::left_join(
      financial_clean,
      by = dplyr::join_by(ticker, date >= reportedDate)
    ) %>%
    dplyr::group_by(ticker, date) %>%
    dplyr::slice_max(reportedDate, n = 1, with_ties = FALSE) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      has_financial_data = !is.na(commonStockSharesOutstanding),
      commonStockSharesOutstanding = as.numeric(commonStockSharesOutstanding)
    ) %>%
    dplyr::arrange(date)

  # Compute cumulative split factors
  prices_with_splits <- prices_clean %>%
    dplyr::left_join(splits_clean, by = c("ticker", "date")) %>%
    dplyr::arrange(date) %>%
    dplyr::mutate(
      split_factor = dplyr::coalesce(split_factor, 1),
      cum_split_factor = cumprod(split_factor)
    )

  # Assemble market cap table with split adjustment
  market_cap <- daily_shares %>%
    dplyr::left_join(
      prices_with_splits %>%
        dplyr::select(ticker, date, cum_split_factor),
      by = c("ticker", "date")
    ) %>%
    dplyr::arrange(date) %>%
    dplyr::mutate(
      post_filing_split_multiplier = dplyr::case_when(
        is.na(reportedDate) | is.na(cum_split_factor) ~ NA_real_,
        TRUE ~ {
          filing_date_indices <- which(date <= reportedDate)
          if (length(filing_date_indices) == 0) {
            filing_date_factor <- 1
          } else {
            last_filing_index <- max(filing_date_indices)
            filing_date_factor <- cum_split_factor[last_filing_index]
            if (is.na(filing_date_factor)) filing_date_factor <- 1
          }
          cum_split_factor / filing_date_factor
        }
      ),
      effective_shares_outstanding = commonStockSharesOutstanding *
        dplyr::coalesce(post_filing_split_multiplier, 1),
      market_cap = dplyr::if_else(
        has_financial_data,
        close * effective_shares_outstanding / 1e6,
        NA_real_
      )
    ) %>%
    dplyr::select(
      ticker,
      date,
      post_filing_split_multiplier,
      effective_shares_outstanding,
      market_cap
    ) %>%
    dplyr::arrange(date)

  market_cap
}
