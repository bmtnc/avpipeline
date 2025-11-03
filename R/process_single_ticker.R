#' Process Complete TTM Pipeline for Single Ticker
#'
#' Orchestrates all pipeline stages for a single ticker: fetch financial data,
#' clean statements, calculate market cap with split adjustments, compute TTM
#' metrics, forward-fill financial data, and calculate per-share metrics.
#' This function processes one ticker completely in memory before returning.
#'
#' @param ticker character: Stock ticker symbol (e.g., "AAPL")
#' @param start_date Date: Start date for filtering financial data
#' @param threshold numeric: Z-score threshold for anomaly detection (default 4)
#' @param lookback integer: Number of observations to look back for anomaly detection (default 5)
#' @param lookahead integer: Number of observations to look ahead for anomaly detection (default 5)
#' @param end_window_size integer: Window size for end-of-series anomaly detection (default 5)
#' @param end_threshold numeric: Threshold for end-of-series anomaly detection (default 3)
#' @param min_obs integer: Minimum observations required for anomaly detection (default 10)
#' @param delay_seconds numeric: API delay between requests in seconds (default 1)
#' @return list: Contains 'data' (tibble with TTM per-share financial data) and 'api_log' (tibble with API call status)
#' @keywords internal
process_single_ticker <- function(ticker,
                                   start_date,
                                   threshold = 4,
                                   lookback = 5,
                                   lookahead = 5,
                                   end_window_size = 5,
                                   end_threshold = 3,
                                   min_obs = 10,
                                   delay_seconds = 1) {
  # Input validation
  if (!is.character(ticker) || length(ticker) != 1 || nchar(ticker) == 0) {
    stop(paste0(
      "process_single_ticker(): [ticker] must be a non-empty character scalar, not ",
      class(ticker)[1], " of length ", length(ticker)
    ))
  }
  if (!inherits(start_date, "Date") || length(start_date) != 1) {
    stop(paste0(
      "process_single_ticker(): [start_date] must be a Date scalar, not ",
      class(start_date)[1], " of length ", length(start_date)
    ))
  }
  if (!is.numeric(threshold) || length(threshold) != 1 || threshold <= 0) {
    stop(paste0(
      "process_single_ticker(): [threshold] must be a positive numeric scalar, not ",
      class(threshold)[1], " of length ", length(threshold)
    ))
  }
  if (!is.numeric(delay_seconds) || length(delay_seconds) != 1 || delay_seconds < 0) {
    stop(paste0(
      "process_single_ticker(): [delay_seconds] must be a non-negative numeric scalar, not ",
      class(delay_seconds)[1], " of length ", length(delay_seconds)
    ))
  }

  # ============================================================================
  # FETCH DATA
  # ============================================================================
  
  # Initialize API log
  api_log <- tibble::tibble(
    ticker = character(),
    endpoint = character(),
    status_message = character()
  )
  
  # Fetch balance sheet
  balance_sheet_result <- tryCatch(
    {
      result <- fetch_single_ticker_data(ticker, BALANCE_SHEET_CONFIG, datatype = "json")
      api_log <- dplyr::bind_rows(api_log, tibble::tibble(
        ticker = ticker,
        endpoint = "balance_sheet",
        status_message = "successful"
      ))
      result
    },
    error = function(e) {
      api_log <<- dplyr::bind_rows(api_log, tibble::tibble(
        ticker = ticker,
        endpoint = "balance_sheet",
        status_message = paste0("Error: ", conditionMessage(e))
      ))
      tibble::tibble()
    }
  )
  balance_sheet <- balance_sheet_result
  Sys.sleep(delay_seconds)
  
  # Fetch income statement
  income_statement_result <- tryCatch(
    {
      result <- fetch_single_ticker_data(ticker, INCOME_STATEMENT_CONFIG, datatype = "json")
      api_log <- dplyr::bind_rows(api_log, tibble::tibble(
        ticker = ticker,
        endpoint = "income_statement",
        status_message = "successful"
      ))
      result
    },
    error = function(e) {
      api_log <<- dplyr::bind_rows(api_log, tibble::tibble(
        ticker = ticker,
        endpoint = "income_statement",
        status_message = paste0("Error: ", conditionMessage(e))
      ))
      tibble::tibble()
    }
  )
  income_statement <- income_statement_result
  Sys.sleep(delay_seconds)
  
  # Fetch cash flow
  cash_flow_result <- tryCatch(
    {
      result <- fetch_single_ticker_data(ticker, CASH_FLOW_CONFIG, datatype = "json")
      api_log <- dplyr::bind_rows(api_log, tibble::tibble(
        ticker = ticker,
        endpoint = "cash_flow",
        status_message = "successful"
      ))
      result
    },
    error = function(e) {
      api_log <<- dplyr::bind_rows(api_log, tibble::tibble(
        ticker = ticker,
        endpoint = "cash_flow",
        status_message = paste0("Error: ", conditionMessage(e))
      ))
      tibble::tibble()
    }
  )
  cash_flow <- cash_flow_result
  Sys.sleep(delay_seconds)
  
  # Fetch earnings
  earnings_result <- tryCatch(
    {
      result <- fetch_single_ticker_data(ticker, EARNINGS_CONFIG, datatype = "json")
      api_log <- dplyr::bind_rows(api_log, tibble::tibble(
        ticker = ticker,
        endpoint = "earnings",
        status_message = "successful"
      ))
      result
    },
    error = function(e) {
      api_log <<- dplyr::bind_rows(api_log, tibble::tibble(
        ticker = ticker,
        endpoint = "earnings",
        status_message = paste0("Error: ", conditionMessage(e))
      ))
      tibble::tibble()
    }
  )
  earnings <- earnings_result
  Sys.sleep(delay_seconds)
  
  # Fetch price data
  price_data_result <- tryCatch(
    {
      result <- fetch_single_ticker_data(ticker, PRICE_CONFIG, outputsize = "full", datatype = "json")
      api_log <- dplyr::bind_rows(api_log, tibble::tibble(
        ticker = ticker,
        endpoint = "price_data",
        status_message = "successful"
      ))
      result
    },
    error = function(e) {
      api_log <<- dplyr::bind_rows(api_log, tibble::tibble(
        ticker = ticker,
        endpoint = "price_data",
        status_message = paste0("Error: ", conditionMessage(e))
      ))
      tibble::tibble()
    }
  )
  price_data <- price_data_result
  Sys.sleep(delay_seconds)
  
  # Fetch splits data
  splits_data_result <- tryCatch(
    {
      result <- fetch_single_ticker_data(ticker, SPLITS_CONFIG)
      api_log <- dplyr::bind_rows(api_log, tibble::tibble(
        ticker = ticker,
        endpoint = "splits_data",
        status_message = "successful"
      ))
      result
    },
    error = function(e) {
      api_log <<- dplyr::bind_rows(api_log, tibble::tibble(
        ticker = ticker,
        endpoint = "splits_data",
        status_message = paste0("Error: ", conditionMessage(e))
      ))
      tibble::tibble()
    }
  )
  splits_data <- splits_data_result
  
  # Check if we have minimal data
  if (nrow(earnings) == 0 || nrow(price_data) == 0) {
    return(list(data = NULL, api_log = api_log))
  }
  
  # ============================================================================
  # CLEAN FINANCIAL STATEMENTS
  # ============================================================================
  
  # Remove all-NA observations
  statements_cleaned <- remove_all_na_financial_observations(list(
    cash_flow = cash_flow,
    income_statement = income_statement,
    balance_sheet = balance_sheet
  ))
  
  # Detect and clean anomalies
  statements_cleaned <- clean_all_statement_anomalies(
    statements = statements_cleaned,
    threshold = threshold,
    lookback = lookback,
    lookahead = lookahead,
    end_window_size = end_window_size,
    end_threshold = end_threshold,
    min_obs = min_obs
  )
  
  # Align tickers across statements
  all_statements_aligned <- align_statement_tickers(list(
    earnings = earnings,
    cash_flow = statements_cleaned$cash_flow,
    income_statement = statements_cleaned$income_statement,
    balance_sheet = statements_cleaned$balance_sheet
  ))
  
  # Align dates across statements
  valid_dates <- align_statement_dates(list(
    cash_flow = all_statements_aligned$cash_flow,
    income_statement = all_statements_aligned$income_statement,
    balance_sheet = all_statements_aligned$balance_sheet
  ))
  
  # Join all financial statements
  financial_statements <- join_all_financial_statements(all_statements_aligned, valid_dates)
  
  # Add quality flags and filter columns
  financial_statements <- add_quality_flags(financial_statements)
  financial_statements <- filter_essential_financial_columns(financial_statements)
  
  # Validate quarterly continuity
  financial_statements <- validate_quarterly_continuity(financial_statements)
  
  # Standardize to calendar quarters
  financial_statements <- standardize_to_calendar_quarters(financial_statements)
  
  # Check if we have financial data after cleaning
  if (nrow(financial_statements) == 0) {
    return(list(data = NULL, api_log = api_log))
  }
  
  # ============================================================================
  # BUILD MARKET CAP WITH SPLIT ADJUSTMENT
  # ============================================================================
  
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
      effective_shares_outstanding =
        commonStockSharesOutstanding *
        dplyr::coalesce(post_filing_split_multiplier, 1),
      market_cap = dplyr::if_else(
        has_financial_data,
        close * effective_shares_outstanding / 1e6,
        NA_real_
      )
    ) %>%
    dplyr::select(
      ticker, date,
      post_filing_split_multiplier, effective_shares_outstanding,
      market_cap
    ) %>%
    dplyr::arrange(date)
  
  # ============================================================================
  # CALCULATE TTM METRICS AND PER-SHARE VALUES
  # ============================================================================
  
  # Calculate TTM metrics
  flow_metrics <- c(get_income_statement_metrics(), get_cash_flow_metrics())
  balance_sheet_metrics <- get_balance_sheet_metrics()
  
  ttm_metrics <- calculate_ttm_metrics(financial_statements, flow_metrics) %>%
    dplyr::mutate(date = reportedDate)
  
  # Join daily and financial data
  unified_data <- join_daily_and_financial_data(price_data, market_cap, ttm_metrics)
  
  # Forward fill financial data
  unified_data <- forward_fill_financial_data(unified_data)
  
  # Calculate per-share metrics
  ttm_flow_metrics <- paste0(flow_metrics, "_ttm")
  all_financial_metrics <- c(balance_sheet_metrics, flow_metrics, ttm_flow_metrics)
  unified_per_share_data <- calculate_per_share_metrics(unified_data, all_financial_metrics)
  
  # Select essential columns
  ttm_per_share_data <- select_essential_columns(unified_per_share_data)
  
  # Add derived financial metrics
  ttm_per_share_data <- add_derived_financial_metrics(ttm_per_share_data)
  
  # Add data quality flag
  ttm_per_share_data <- ttm_per_share_data %>%
    dplyr::mutate(
      has_complete_financial_data =
        !is.na(totalRevenue_ttm_per_share) &
        !is.na(totalAssets_per_share) &
        !is.na(operatingCashflow_ttm_per_share)
    )
  
  # Reorder columns: ticker, dates, meta, flag, then everything else
  date_cols <- c(
    "date",
    "initial_date",
    "latest_date",
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
  
  ttm_per_share_data <- ttm_per_share_data %>%
    dplyr::select(
      ticker,
      dplyr::any_of(date_cols),
      dplyr::any_of(meta_cols),
      has_complete_financial_data,
      dplyr::everything()
    ) %>%
    dplyr::arrange(ticker, date)
  
  list(data = ttm_per_share_data, api_log = api_log)
}
