# Function Usage Analysis - avpipeline R Package

**Last Updated:** 2025-12-16
**Total Functions:** 112
**Used Functions:** 101 (90.2%)
**Unused Functions:** 11 (9.8%)

---

## 🚨 Unused Functions (11 total - Candidates for Removal)

- [ ] `fetch_multiple_ticker_data` (NOT USED - superseded by ticker-by-ticker architecture)
- [ ] `get_spy_constituents` (NOT USED - utility function never needed)
- [ ] `load_and_filter_financial_data` (NOT USED - unused helper)
- [ ] `log_data_discrepancy` (NOT USED - utility function with no callers)
- [ ] `parse_balance_sheet_response` (NOT USED - legacy parser, replaced by config-based approach)
- [ ] `parse_cash_flow_response` (NOT USED - legacy parser, replaced by config-based approach)
- [ ] `parse_earnings_response` (NOT USED - legacy parser, replaced by config-based approach)
- [ ] `parse_income_statement_response` (NOT USED - legacy parser, replaced by config-based approach)
- [ ] `parse_price_response` (NOT USED - legacy parser, replaced by config-based approach)
- [ ] `parse_splits_response` (NOT USED - legacy parser, replaced by config-based approach)
- [ ] `s3_check_ticker_raw_data_exists` (NOT USED - unused AWS utility)

---

## 📋 Complete Function Checklist (All 112 Functions)

### Anomaly Detection Functions

- [ ] `add_anomaly_flag_columns` (used in: clean_quarterly_metrics.R, test-add_anomaly_flag_columns.R)
- [ ] `clean_all_statement_anomalies` (used in: validate_and_prepare_statements.R, build_complete_ttm_pipeline.R, financial_statements_artifact.R, test-clean_all_statement_anomalies.R)
- [ ] `clean_end_window_anomalies` (used in: clean_single_statement_anomalies.R, test-clean_end_window_anomalies.R)
- [ ] `clean_single_statement_anomalies` (used in: clean_all_statement_anomalies.R, test-clean_single_statement_anomalies.R)
- [ ] `detect_baseline_anomaly` (used in: detect_single_baseline_anomaly.R, test-detect_baseline_anomaly.R, test-detect_single_baseline_anomaly.R)
- [ ] `detect_single_baseline_anomaly` (used in: test-detect_single_baseline_anomaly.R)
- [ ] `detect_temporary_anomalies` (used in: add_anomaly_flag_columns.R, test-detect_temporary_anomalies.R)
- [ ] `detect_time_series_anomalies` (used in: clean_end_window_anomalies.R, test-detect_time_series_anomalies.R)

### Baseline Calculation Functions

- [ ] `calculate_baseline` (used in: detect_single_baseline_anomaly.R, test-calculate_baseline.R, test-detect_single_baseline_anomaly.R)
- [ ] `calculate_baseline_stats` (used in: detect_single_baseline_anomaly.R, test-calculate_baseline_stats.R, test-detect_single_baseline_anomaly.R)

### Financial Metrics Calculation Functions

- [ ] `add_derived_financial_metrics` (used in: calculate_unified_ttm_per_share_metrics.R, build_complete_ttm_pipeline.R, ttm_per_share_unified_financial_artifact.R, test-add_derived_financial_metrics.R)
- [ ] `calculate_enterprise_value_per_share` (used in: add_derived_financial_metrics.R, test-calculate_enterprise_value_per_share.R)
- [ ] `calculate_fcf_per_share` (used in: add_derived_financial_metrics.R, test-calculate_fcf_per_share.R)
- [ ] `calculate_invested_capital_per_share` (used in: add_derived_financial_metrics.R, test-calculate_invested_capital_per_share.R)
- [ ] `calculate_nopat_per_share` (used in: add_derived_financial_metrics.R, test-calculate_nopat_per_share.R)
- [ ] `calculate_per_share_metrics` (used in: calculate_unified_ttm_per_share_metrics.R, build_complete_ttm_pipeline.R, ttm_per_share_unified_financial_artifact.R)
- [ ] `calculate_ttm_metrics` (used in: calculate_unified_ttm_per_share_metrics.R, build_complete_ttm_pipeline.R, ttm_per_share_unified_financial_artifact.R)
- [ ] `calculate_unified_ttm_per_share_metrics` (used in: process_single_ticker.R, process_ticker_from_s3.R)

### Data Cleaning & Filtering Functions

- [ ] `clean_original_columns` (used in: clean_quarterly_metrics.R, test-clean_original_columns.R)
- [ ] `clean_quarterly_metrics` (used in: clean_single_statement_anomalies.R, test-clean_quarterly_metrics.R)
- [ ] `filter_essential_financial_columns` (used in: validate_and_prepare_statements.R, build_complete_ttm_pipeline.R, financial_statements_artifact.R, test-filter_essential_financial_columns.R)
- [ ] `filter_sufficient_observations` (used in: clean_single_statement_anomalies.R, test-filter_sufficient_observations.R)
- [ ] `remove_all_na_financial_observations` (used in: validate_and_prepare_statements.R, build_complete_ttm_pipeline.R, financial_statements_artifact.R, test-remove_all_na_financial_observations.R)
- [ ] `select_essential_columns` (used in: calculate_unified_ttm_per_share_metrics.R, build_complete_ttm_pipeline.R, ttm_per_share_unified_financial_artifact.R, test-select_essential_columns.R)

### Statement Alignment & Joining Functions

- [ ] `align_statement_dates` (used in: validate_and_prepare_statements.R, build_complete_ttm_pipeline.R, financial_statements_artifact.R, test-align_statement_dates.R)
- [ ] `align_statement_tickers` (used in: validate_and_prepare_statements.R, build_complete_ttm_pipeline.R, financial_statements_artifact.R, test-align_statement_tickers.R)
- [ ] `join_all_financial_statements` (used in: validate_and_prepare_statements.R, build_complete_ttm_pipeline.R, financial_statements_artifact.R, test-join_all_financial_statements.R)
- [ ] `join_daily_and_financial_data` (used in: calculate_unified_ttm_per_share_metrics.R, build_complete_ttm_pipeline.R, ttm_per_share_unified_financial_artifact.R, test-join_daily_and_financial_data.R)

### Validation & Quality Functions

- [ ] `add_quality_flags` (used in: validate_and_prepare_statements.R, build_complete_ttm_pipeline.R, financial_statements_artifact.R, test-add_quality_flags.R)
- [ ] `extract_quarterly_pattern` (used in: validate_continuous_quarters.R, test-extract_quarterly_pattern.R, test-generate_month_end_dates.R)
- [ ] `identify_all_na_rows` (used in: remove_all_na_financial_observations.R, test-identify_all_na_rows.R)
- [ ] `validate_and_prepare_statements` (used in: process_single_ticker.R, process_ticker_from_s3.R, test-validate_and_prepare_statements.R)
- [ ] `validate_artifact_files` (used in: load_all_artifact_statements.R, test-validate_artifact_files.R)
- [ ] `validate_continuous_quarters` (used in: test-validate_continuous_quarters.R)
- [ ] `validate_df_cols` (used in: 15 different functions including add_anomaly_flag_columns.R, add_derived_financial_metrics.R, clean_end_window_anomalies.R, join_all_financial_statements.R, etc.)
- [ ] `validate_df_type` (used in: 9 different functions including add_quality_flags.R, detect_data_loss.R, filter_essential_financial_columns.R, forward_fill_financial_data.R, get_ticker_tracking.R)
- [ ] `validate_non_empty` (used in: clean_original_columns.R, filter_sufficient_observations.R)
- [ ] `validate_month_end_date` (used in: generate_month_end_dates.R, validate_continuous_quarters.R, test-validate_month_end_date.R)
- [ ] `validate_quarterly_consistency` (used in: test-data_validation.R)
- [ ] `validate_quarterly_continuity` (used in: validate_and_prepare_statements.R, build_complete_ttm_pipeline.R, financial_statements_artifact.R, test-validate_quarterly_continuity.R)

### Fetching Functions

- [ ] `fetch_all_financial_statements` (used in: build_complete_ttm_pipeline.R)
- [ ] `fetch_all_ticker_data` (used in: process_single_ticker.R)
- [ ] `fetch_and_store_single_data_type` (used in: fetch_and_store_ticker_data.R, test-fetch_and_store_single_data_type.R)
- [ ] `fetch_and_store_ticker_data` (used in: run_phase1_fetch.R, test-fetch_and_store_ticker_data.R)
- [ ] `fetch_etf_holdings` (used in: get_financial_statement_tickers.R, price_artifact.R)
- [ ] `fetch_multiple_tickers_with_cache` (used in: fetch_single_financial_type.R, build_complete_ttm_pipeline.R, price_artifact.R, splits_artifact.R)
- [ ] `fetch_single_financial_type` (used in: fetch_all_financial_statements.R, test-fetch_single_financial_type.R)
- [ ] `fetch_single_ticker_data` (used in: alpha_vantage_configs.R, fetch_all_ticker_data.R, fetch_and_store_single_data_type.R, fetch_single_financial_type.R, fetch_tickers_with_progress.R, build_complete_ttm_pipeline.R, price_artifact.R, splits_artifact.R)
- [ ] `fetch_tickers_with_progress` (used in: fetch_multiple_ticker_data.R)

### API & Request Functions

- [ ] `get_api_key` (used in: fetch_etf_holdings.R, fetch_multiple_ticker_data.R, fetch_single_ticker_data.R, fetch_tickers_with_progress.R, make_alpha_vantage_request.R)
- [ ] `get_api_key_from_parameter_store` (used in: run_phase1_fetch.R)
- [ ] `make_alpha_vantage_request` (used in: fetch_etf_holdings.R, fetch_single_ticker_data.R)

### Metric Getter Functions

- [ ] `get_balance_sheet_metrics` (used in: add_quality_flags.R, calculate_unified_ttm_per_share_metrics.R, filter_essential_financial_columns.R, build_complete_ttm_pipeline.R, ttm_per_share_unified_financial_artifact.R)
- [ ] `get_cash_flow_metrics` (used in: add_quality_flags.R, calculate_unified_ttm_per_share_metrics.R, filter_essential_financial_columns.R, build_complete_ttm_pipeline.R, ttm_per_share_unified_financial_artifact.R)
- [ ] `get_income_statement_metrics` (used in: add_quality_flags.R, calculate_unified_ttm_per_share_metrics.R, filter_essential_financial_columns.R, build_complete_ttm_pipeline.R, ttm_per_share_unified_financial_artifact.R)

### Configuration & Lookup Functions

- [ ] `get_config_for_data_type` (used in: fetch_and_store_single_data_type.R, test-get_config_for_data_type.R)
- [ ] `get_financial_cache_paths` (used in: fetch_all_financial_statements.R, load_all_financial_statements.R, build_complete_ttm_pipeline.R, test-get_financial_cache_paths.R)
- [ ] `get_financial_statement_tickers` (used in: build_complete_ttm_pipeline_ticker_by_ticker.R, build_complete_ttm_pipeline.R, run_phase1_fetch.R, run_phase2_generate.R, test-get_financial_statement_tickers.R)

### Data Loading Functions

- [ ] `load_all_artifact_statements` (used in: build_complete_ttm_pipeline.R, financial_statements_artifact.R, test-load_all_artifact_statements.R)
- [ ] `load_all_financial_statements` (used in: test-load_all_financial_statements.R)
- [ ] `load_financial_artifacts` (used in: ttm_per_share_unified_financial_artifact.R, test-load_financial_artifacts.R)
- [ ] `load_single_financial_type` (used in: load_all_financial_statements.R, test-load_single_financial_type.R)
- [ ] `read_cached_data` (used in: load_and_filter_financial_data.R, load_financial_artifacts.R, market_cap_artifact.R, price_artifact.R, splits_artifact.R)
- [ ] `read_cached_data_parquet` (used in: load_all_artifact_statements.R, load_single_financial_type.R)

### Data Transformation Functions

- [ ] `forward_fill_financial_data` (used in: calculate_unified_ttm_per_share_metrics.R, build_complete_ttm_pipeline.R, ttm_per_share_unified_financial_artifact.R, test-forward_fill_financial_data.R)
- [ ] `standardize_to_calendar_quarters` (used in: validate_and_prepare_statements.R, build_complete_ttm_pipeline.R, financial_statements_artifact.R, test-standardize_to_calendar_quarters.R)

### Date Generation Functions

- [ ] `generate_month_end_dates` (used in: validate_continuous_quarters.R, test-extract_quarterly_pattern.R, test-generate_month_end_dates.R)
- [ ] `generate_raw_data_s3_key` (used in: s3_read_ticker_raw_data_single.R, s3_write_ticker_raw_data.R, test-s3_raw_data_operations.R)
- [ ] `generate_s3_artifact_key` (used in: run_phase2_generate.R, run_pipeline_aws.R)
- [ ] `generate_version_snapshot_s3_key` (used in: s3_write_version_snapshot.R, test-s3_raw_data_operations.R)

### Market Cap Functions

- [ ] `build_market_cap_with_splits` (used in: process_single_ticker.R, process_ticker_from_s3.R, test-build_market_cap_with_splits.R)

### Ticker Processing Functions

- [ ] `combine_ticker_results` (used in: fetch_multiple_ticker_data.R)
- [ ] `process_single_ticker` (used in: build_complete_ttm_pipeline_ticker_by_ticker.R, test_ticker_by_ticker_small.R)
- [ ] `process_ticker_from_s3` (used in: run_phase2_generate.R, test-process_ticker_from_s3.R)

### Earnings & Refresh Logic Functions

- [ ] `calculate_median_report_delay` (used in: update_earnings_prediction.R, test-refresh_logic.R)
- [ ] `calculate_next_estimated_report_date` (used in: update_earnings_prediction.R, test-refresh_logic.R)
- [ ] `create_default_ticker_tracking` (used in: get_ticker_tracking.R, update_ticker_tracking.R, test-refresh_logic.R, test-refresh_tracking.R)
- [ ] `create_empty_refresh_tracking` (used in: s3_read_refresh_tracking.R, test-refresh_logic.R, test-refresh_tracking.R)
- [ ] `detect_data_changes` (used in: test-refresh_logic.R)
- [ ] `detect_data_loss` (used in: test-data_validation.R)
- [ ] `determine_fetch_requirements` (used in: fetch_and_store_ticker_data.R, run_phase1_fetch.R, test-refresh_logic.R)
- [ ] `determine_missing_symbols` (used in: fetch_multiple_tickers_with_cache.R)
- [ ] `get_ticker_tracking` (used in: run_phase1_fetch.R, test-refresh_tracking.R)
- [ ] `should_fetch_quarterly_data` (used in: determine_fetch_requirements.R, test-refresh_logic.R)
- [ ] `update_earnings_prediction` (used in: run_phase1_fetch.R, test-refresh_logic.R)
- [ ] `update_ticker_tracking` (used in: update_earnings_prediction.R, update_tracking_after_error.R, update_tracking_after_fetch.R, test-refresh_tracking.R)
- [ ] `update_tracking_after_error` (used in: run_phase1_fetch.R, test-refresh_tracking.R)
- [ ] `update_tracking_after_fetch` (used in: run_phase1_fetch.R, test-refresh_tracking.R)

### Parsing Functions

- [ ] `parse_etf_profile_response` (used in: fetch_etf_holdings.R)

### S3 Functions

- [ ] `s3_read_refresh_tracking` (used in: run_phase1_fetch.R)
- [ ] `s3_read_ticker_raw_data` (used in: process_ticker_from_s3.R)
- [ ] `s3_read_ticker_raw_data_single` (used in: s3_read_ticker_raw_data.R, s3_write_version_snapshot.R)
- [ ] `s3_write_refresh_tracking` (used in: run_phase1_fetch.R)
- [ ] `s3_write_ticker_raw_data` (used in: fetch_and_store_single_data_type.R)
- [ ] `s3_write_version_snapshot` (used in: fetch_and_store_single_data_type.R)
- [ ] `upload_artifact_to_s3` (used in: s3_write_refresh_tracking.R, s3_write_ticker_raw_data.R, s3_write_version_snapshot.R, run_phase2_generate.R)

### Visualization & Reporting Functions

- [ ] `create_ticker_count_plot` (used in: financial_statements_artifact.R, test-create_ticker_count_plot.R)
- [ ] `send_pipeline_notification` (used in: run_pipeline_aws.R)
- [ ] `set_ggplot_theme` (used in: explore_ttm_artifact.R)
- [ ] `summarize_artifact_construction` (used in: financial_statements_artifact.R, test-summarize_artifact_construction.R)
- [ ] `summarize_financial_data_fetch` (used in: test-summarize_financial_data_fetch.R)

---

## 📊 Key Insights

### Parser Functions Status
Six legacy parser functions are unused, representing a shift to configuration-based parsing:
- **Legacy (unused):** `parse_balance_sheet_response`, `parse_cash_flow_response`, `parse_earnings_response`, `parse_income_statement_response`, `parse_price_response`, `parse_splits_response`
- **Active:** `parse_etf_profile_response` (used by fetch_etf_holdings.R)

This suggests your codebase migrated to a more generic parsing architecture using configuration objects.

### Most Reusable Functions
Functions called in 5+ locations:
- `validate_df_cols` (15 callers) - Core validation workhorse
- `fetch_single_ticker_data` (8 callers) - Primary data fetcher
- `get_balance_sheet_metrics`, `get_cash_flow_metrics`, `get_income_statement_metrics` (5 callers each) - Metric configurations

### Architecture Observations
- **Ticker-by-ticker processing:** `process_single_ticker` is the main entry point for the production pipeline
- **Configuration-driven design:** Config objects are used throughout rather than individual fetch functions
- **Extensive validation:** Multiple validation helper functions provide robustness
