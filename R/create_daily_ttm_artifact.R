#' Create Daily TTM Artifact from Quarterly and Price Data
#'
#' Joins quarterly TTM financials with daily price data to create a daily-frequency
#' artifact with forward-filled financials, split-adjusted shares, and per-share metrics.
#' Uses existing pipeline functions to ensure identical output.
#'
#' @param quarterly_df tibble: Quarterly TTM financial data from Phase 2
#' @param price_df tibble: Daily price data with split_coefficient
#' @param tickers character: Optional vector of tickers to filter to
#' @param start_date Date: Optional start date for filtering
#' @return tibble: Daily-frequency dataset with TTM per-share metrics
#' @export
create_daily_ttm_artifact <- function(
    quarterly_df,
    price_df,
    tickers = NULL,
    start_date = NULL
) {
  # Filter by tickers if specified
  if (!is.null(tickers)) {
    if (!is.character(tickers)) {
      stop("tickers must be a character vector")
    }
    quarterly_df <- quarterly_df |>
      dplyr::filter(ticker %in% tickers)
    price_df <- price_df |>
      dplyr::filter(ticker %in% tickers)
  }

  # Get unique tickers to process
  all_tickers <- unique(quarterly_df$ticker)

  # Process each ticker using the same logic as process_ticker_from_memory
 results <- lapply(all_tickers, function(tkr) {
    tryCatch({
      # Filter data for this ticker
      ticker_quarterly <- quarterly_df |>
        dplyr::filter(ticker == tkr)
      ticker_price <- price_df |>
        dplyr::filter(ticker == tkr)

      if (nrow(ticker_quarterly) == 0 || nrow(ticker_price) == 0) {
        return(NULL)
      }

      # Extract splits from price data for build_market_cap_with_splits
      splits_data <- ticker_price |>
        dplyr::filter(
          !is.na(split_coefficient) & split_coefficient != 1
        ) |>
        dplyr::select(
          ticker,
          effective_date = date,
          split_factor = split_coefficient
        )

      # Use start_date if provided, otherwise use earliest fiscal date
      effective_start_date <- if (!is.null(start_date)) {
        start_date
      } else {
        min(ticker_quarterly$fiscalDateEnding, na.rm = TRUE)
      }

      # Call the EXISTING build_market_cap_with_splits function
      market_cap <- build_market_cap_with_splits(
        price_data = ticker_price,
        splits_data = splits_data,
        financial_statements = ticker_quarterly,
        start_date = effective_start_date
      )

      # Call the EXISTING calculate_unified_ttm_per_share_metrics function
      result <- calculate_unified_ttm_per_share_metrics(
        financial_statements = ticker_quarterly,
        price_data = ticker_price,
        market_cap = market_cap
      )

      # Add overview columns from quarterly data
      overview_cols <- c(
        "cik", "exchange", "currency", "country", "sector", "industry"
      )
      for (col in overview_cols) {
        if (col %in% names(ticker_quarterly)) {
          result[[col]] <- ticker_quarterly[[col]][1]
        } else {
          result[[col]] <- NA_character_
        }
      }

      result
    }, error = function(e) {
      NULL
    })
  })

  # Combine results
  dplyr::bind_rows(results)
}
