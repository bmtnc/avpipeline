# Lightweight TTM Per-Share Artifact Creator - ESSENTIAL ONLY VERSION

devtools::load_all()

cat("Creating TTM per-share artifact (essential columns only)...\n")

#' quarterly frequency df (long form) indexed by:
#'  - `ticker`,
#'  - `fiscalDateEnding`,
#'  - `calendar_quarter_ending`
#'  - `reportedDate`
#' notes: the `as_of_date` column is just the timestamp when the data was pulled
#' from the av api; `reportedDate` is the date of the earnings event
#' `reportedDate` should be used to join on price data

financial_statements <- read_cached_data(
  "cache/financial_statements_artifact.csv",
  date_columns = c(
    "fiscalDateEnding",
    "calendar_quarter_ending",
    "reportedDate",
    "as_of_date"
  )
)

#' daily frequency (long form) df indexed by: `ticker` & `date` cols
#' notes: `reportedDate` is the date of the earnings event, i.e., when the
#' share count is updated
#' `commonStockSharesOutstanding` is the quarterly share count reported by AV;
#' it has been adjusted for share splits (this isn't documented on AV)
#' `effective_shares_outstanding` is the UN-ADJUSTED share count; it is used to
#' calculate `market_cap` = `close` * `effective_shares_outstanding`
#' note: adjusted close includes the impact of dividend reinvestment so we do
#' NOT use it to calculate market cap. this is why we needed to back-out the
#' un-adjusted shares outstanding `effective_shares_outstanding` so we can
#' multiply the un-adjusted close to calc market cap

market_cap_data <- read_cached_data(
  "cache/market_cap_artifact_vectorized.csv",
  date_columns = c("date", "reportedDate", "as_of_date")
)


#' daily frequency (long form) df indexed by: `ticker` & `date` cols

price_data <- read_cached_data(
  "cache/price_artifact.csv",
  date_columns = c("date", "as_of_date")
)

# Calculate TTM
flow_metrics <- c(get_income_statement_metrics(), get_cash_flow_metrics())
balance_sheet_metrics <- get_balance_sheet_metrics()
ttm_metrics <- calculate_ttm_metrics(financial_statements, flow_metrics) %>%
  dplyr::mutate(date = reportedDate)

# drop unnecessary columns
price_data <- price_data %>%
  dplyr::select(-as_of_date)

market_cap_data <- market_cap_data %>%
  dplyr::select(
    -as_of_date,
    -close,
    -commonStockSharesOutstanding,
    -has_financial_data,
    -days_since_financial_report,
    -reportedDate
  )

unified_data <- price_data %>%
  dplyr::left_join(
    .,
    y = market_cap_data,
    by = c("ticker", "date")
  ) %>%
  dplyr::left_join(
    .,
    y = ttm_metrics,
    by = c("ticker", "date")
  ) %>%
  dplyr::group_by(ticker) %>%
  tidyr::fill(dplyr::everything(), .direction = "down") %>%
  dplyr::ungroup() %>%
  dplyr::select(
    ticker,
    date,
    dplyr::contains("date"),
    dplyr::everything()
  )

# Create per-share metrics
ttm_flow_metrics <- paste0(flow_metrics, "_ttm")
all_financial_metrics <- c(
  balance_sheet_metrics,
  flow_metrics,
  ttm_flow_metrics
)

unified_per_share_data <- calculate_per_share_metrics(
  unified_data,
  all_financial_metrics
)

# NOW - Keep only essential columns
cat("Filtering to essential columns only...\n")

date_cols <- c(
  "date",
  "initial_date",
  "latest_date",
  "fiscalDateEnding",
  "reportedDate"
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

ttm_per_share_data <- unified_per_share_data %>%
  dplyr::select(
    dplyr::any_of(date_cols),
    dplyr::any_of(meta_cols),
    dplyr::contains("per_share")
  ) %>%
  dplyr::mutate(
    #TODO factor this fcf operation out somewhere else
    fcf_ttm_per_share = dplyr::if_else(
      !is.na(operatingCashflow_ttm_per_share) &
        !is.na(capitalExpenditures_ttm_per_share),
      # capex is negative
      operatingCashflow_ttm_per_share + capitalExpenditures_ttm_per_share,
      NA_real_
    ),
    has_complete_financial_data =
      !is.na(totalRevenue_ttm_per_share) &
      !is.na(totalAssets_per_share) &
      !is.na(operatingCashflow_ttm_per_share)
  ) %>%
  dplyr::select(
    ticker,
    dplyr::any_of(date_cols),
    dplyr::any_of(meta_cols),
    has_complete_financial_data,
    dplyr::everything()
  ) %>%
  dplyr::arrange(ticker, date)

# Save
write.csv(ttm_per_share_data, "cache/ttm_per_share_financial_artifact.csv", row.names = FALSE)

cat("✓ Essential TTM per-share artifact created!\n")
cat("Final dataset:", nrow(ttm_per_share_data), "observations x", ncol(ttm_per_share_data), "columns\n")
