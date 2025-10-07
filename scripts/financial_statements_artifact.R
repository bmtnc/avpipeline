# Financial Statements Artifact Constructor
# Creates aligned quarterly financial statements with continuous quarterly validation
# Filters to tickers with complete data alignment and continuous quarterly series

message("Starting financial statements artifact construction...")

all_statements <- load_all_artifact_statements()

statements_cleaned <- remove_all_na_financial_observations(list(
  cash_flow = all_statements$cash_flow,
  income_statement = all_statements$income_statement,
  balance_sheet = all_statements$balance_sheet
))

statements_cleaned <- clean_all_statement_anomalies(
  statements = statements_cleaned,
  threshold = 4,
  lookback = 5,
  lookahead = 5,
  end_window_size = 5,
  end_threshold = 3,
  min_obs = 10
)

all_statements_aligned <- align_statement_tickers(list(
  earnings = all_statements$earnings,
  cash_flow = statements_cleaned$cash_flow,
  income_statement = statements_cleaned$income_statement,
  balance_sheet = statements_cleaned$balance_sheet
))

valid_dates <- align_statement_dates(list(
  cash_flow = all_statements_aligned$cash_flow,
  income_statement = all_statements_aligned$income_statement,
  balance_sheet = all_statements_aligned$balance_sheet
))

financial_statements <- join_all_financial_statements(all_statements_aligned, valid_dates)

financial_statements <- add_quality_flags(financial_statements)

financial_statements <- filter_essential_financial_columns(financial_statements)

original_data <- financial_statements %>%
  dplyr::select(ticker, fiscalDateEnding) %>%
  dplyr::arrange(ticker, fiscalDateEnding)

financial_statements <- validate_quarterly_continuity(financial_statements)

final_data <- financial_statements %>%
  dplyr::select(ticker, fiscalDateEnding) %>%
  dplyr::arrange(ticker, fiscalDateEnding)

removed_detail <- original_data %>%
  dplyr::anti_join(final_data, by = c("ticker", "fiscalDateEnding")) %>%
  dplyr::group_by(ticker) %>%
  dplyr::summarise(
    removed_count = dplyr::n(),
    earliest_removed = min(fiscalDateEnding),
    latest_removed = max(fiscalDateEnding),
    .groups = "drop"
  )

financial_statements <- standardize_to_calendar_quarters(financial_statements)

write.csv(financial_statements, "cache/financial_statements_artifact.csv", row.names = FALSE)
message("Financial statements artifact saved successfully!")

summarize_artifact_construction(original_data, financial_statements, removed_detail)

ticker_plot <- create_ticker_count_plot(financial_statements)
print(ticker_plot)

message("Financial statements artifact construction complete!")
