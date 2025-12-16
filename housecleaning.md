# Housecleaning Tasks

## One Function Per File Violations (PENDING)

7 files contain multiple function definitions and need to be split following the one-function-per-file convention.

### Current Files and Their Functions

| File | Functions |
|------|-----------|
| `R/pipeline_logger.R` | `create_pipeline_log()`, `add_log_entry()`, `print_progress()`, `print_log_summary()`, `upload_pipeline_log()` |
| `R/combine_ticker_results.R` | `combine_ticker_results()`, `%\|\|%` (utility operator) |
| `R/fetch_all_ticker_data.R` | `fetch_all_ticker_data()`, `fetch_with_logging()` (nested helper) |
| `R/fetch_multiple_ticker_data.R` | `fetch_multiple_ticker_data()`, `%\|\|%` (utility operator) |
| `R/fetch_single_ticker_data.R` | `fetch_single_ticker_data()`, `%\|\|%` (utility operator) |
| `R/fetch_tickers_with_progress.R` | `fetch_tickers_with_progress()`, `%\|\|%` (utility operator) |
| `R/s3_read_refresh_tracking.R` | `s3_read_refresh_tracking()`, `migrate_tracking_schema()` |

### Refactoring Plan

**Phase 1: Extract Utility Operator**
- Create `R/null_coalesce.R` containing the `%||%` operator (used by 4 files)
- Remove `%||%` definition from: `fetch_multiple_ticker_data.R`, `fetch_single_ticker_data.R`, `fetch_tickers_with_progress.R`, `combine_ticker_results.R`

**Phase 2: Split Pipeline Logger**
- Create `R/create_pipeline_log.R`
- Create `R/add_log_entry.R`
- Create `R/print_progress.R`
- Create `R/print_log_summary.R`
- Create `R/upload_pipeline_log.R`
- Delete `R/pipeline_logger.R`

**Phase 3: Extract S3 Tracking Helpers**
- Create `R/migrate_tracking_schema.R`
- Keep `s3_read_refresh_tracking()` in `R/s3_read_refresh_tracking.R`

**Phase 4: Extract Fetch Helpers**
- Create `R/fetch_with_logging.R` (extract from `fetch_all_ticker_data.R`)
- Keep `fetch_all_ticker_data()` in `R/fetch_all_ticker_data.R`

### Ideal End State (After Refactoring)

| File | Function | Action |
|------|----------|--------|
| `R/add_log_entry.R` | `add_log_entry()` | Create new file |
| `R/combine_ticker_results.R` | `combine_ticker_results()` | Modify existing (remove `%\|\|%`) |
| `R/create_pipeline_log.R` | `create_pipeline_log()` | Create new file |
| `R/fetch_all_ticker_data.R` | `fetch_all_ticker_data()` | Modify existing (remove `fetch_with_logging()`) |
| `R/fetch_multiple_ticker_data.R` | `fetch_multiple_ticker_data()` | Modify existing (remove `%\|\|%`) |
| `R/fetch_single_ticker_data.R` | `fetch_single_ticker_data()` | Modify existing (remove `%\|\|%`) |
| `R/fetch_tickers_with_progress.R` | `fetch_tickers_with_progress()` | Modify existing (remove `%\|\|%`) |
| `R/fetch_with_logging.R` | `fetch_with_logging()` | Create new file |
| `R/migrate_tracking_schema.R` | `migrate_tracking_schema()` | Create new file |
| `R/null_coalesce.R` | `%\|\|%` | Create new file |
| `R/print_log_summary.R` | `print_log_summary()` | Create new file |
| `R/print_progress.R` | `print_progress()` | Create new file |
| `R/s3_read_refresh_tracking.R` | `s3_read_refresh_tracking()` | Keep as is |
| `R/upload_pipeline_log.R` | `upload_pipeline_log()` | Create new file |
| ~~`R/pipeline_logger.R`~~ | (all functions moved) | Delete |

## Validations (IN PROGRESS)

Validation helper functions have been created. Most functions have been refactored, but some still have manual boilerplate validation code.

### Validation Helpers Created

| Helper Function | Purpose |
|-----------------|---------|
| `validate_character_scalar()` | Single character string validation |
| `validate_numeric_scalar()` | Single numeric value with optional bounds (gt, gte, lt, lte) |
| `validate_positive()` | Positive numeric value (wrapper for validate_numeric_scalar with gt=0) |
| `validate_numeric_vector()` | Numeric vector validation with optional empty check |
| `validate_date_type()` | Date object validation with optional scalar check |
| `validate_file_exists()` | File existence validation |
| `validate_non_empty()` | Non-null, non-empty validation for vectors, lists, and data.frames |
| `validate_api_response()` | Alpha Vantage API error response validation |
| `validate_df_type()` | Data.frame type validation |
| `validate_df_cols()` | Data.frame with required columns validation |

### Functions Still Needing Refactoring (9 functions)

These functions have manual boilerplate validation that should use the helper functions:

| Function | Current State | Refactoring Needed |
|----------|---------------|-------------------|
| `align_statement_dates()` | Manual list type + required names check | Needs `validate_list_keys()` (not yet implemented) |
| `align_statement_tickers()` | Manual list type + required names check | Needs `validate_list_keys()` (not yet implemented) |
| `calculate_next_estimated_report_date()` | Only `is.na()` check, no type validation | Add `validate_date_type()` for parameters |
| `determine_missing_symbols()` | Manual `stop()` calls throughout | Use `validate_character_scalar()`, `validate_df_type()`, `validate_df_cols()` |
| `fetch_all_financial_statements()` | Manual type checks + list key validation | Needs `validate_list_keys()` (not yet implemented) |
| `fetch_multiple_tickers_with_cache()` | Uses `missing()`, `file.exists()`, manual checks | Use `validate_character_scalar()`, `validate_numeric_scalar()`, `validate_date_type()` |
| `load_all_financial_statements()` | Manual list type + required keys validation | Needs `validate_list_keys()` (not yet implemented) |
| `remove_all_na_financial_observations()` | Manual list type + `setdiff()` for keys | Needs `validate_list_keys()` (not yet implemented) |
| `validate_month_end_date()` | Duplicates `validate_date_type()` logic | Replace lines 13-29 with `validate_date_type(date, scalar = TRUE, name = param_name)` |

### Functions with Partial Validator Usage (5 functions)

These functions use some validators but retain manual validation for certain parameters:

| Function | Validators Used | Manual Validation Remaining |
|----------|-----------------|----------------------------|
| `detect_data_loss()` | `validate_df_type()` | Manual null/empty checks for existing_data, manual column existence |
| `filter_sufficient_observations()` | `validate_df_cols()`, `validate_non_empty()` | Manual checks for `group_col` (type/length), `min_obs` (type/bounds) |
| `join_all_financial_statements()` | `validate_df_cols()` | Manual list type check for statements parameter |
| `validate_artifact_files()` | None | Manual char vector validation + file.exists loop (could use `validate_file_exists()`) |
| `validate_quarterly_consistency()` | `validate_df_type()` (in tryCatch) | Intentionally defensive - returns results vs throwing errors |

### Functions Fully Refactored (Using Validators)

These functions have been updated to use the validation helpers:

| Function | Validators Used |
|----------|----------------|
| `add_anomaly_flag_columns()` | `validate_non_empty()`, `validate_df_cols()`, `validate_positive()` |
| `add_derived_financial_metrics()` | `validate_df_cols()` |
| `add_quality_flags()` | `validate_df_type()` |
| `build_market_cap_with_splits()` | `validate_date_type()` |
| `calculate_baseline()` | `validate_numeric_scalar()`, `validate_positive()` |
| `calculate_baseline_stats()` | `validate_numeric_vector()` |
| `calculate_enterprise_value_per_share()` | `validate_numeric_vector()` |
| `calculate_fcf_per_share()` | `validate_numeric_vector()` |
| `calculate_invested_capital_per_share()` | `validate_numeric_vector()` |
| `calculate_median_report_delay()` | `validate_df_cols()` |
| `calculate_nopat_per_share()` | `validate_numeric_vector()`, `validate_numeric_scalar()` |
| `clean_all_statement_anomalies()` | `validate_positive()` |
| `clean_end_window_anomalies()` | `validate_non_empty()`, `validate_df_cols()`, `validate_numeric_scalar()`, `validate_positive()` |
| `clean_original_columns()` | `validate_df_cols()`, `validate_non_empty()` |
| `clean_quarterly_metrics()` | `validate_non_empty()`, `validate_character_scalar()`, `validate_df_type()`, `validate_df_cols()`, `validate_positive()`, `validate_numeric_scalar()` |
| `combine_ticker_results()` | Manual validation (complex multi-type checks) |
| `create_ticker_count_plot()` | `validate_df_cols()` |
| `detect_baseline_anomaly()` | `validate_positive()` |
| `detect_data_changes()` | `validate_df_type()`, `validate_character_scalar()` |
| `detect_single_baseline_anomaly()` | `validate_numeric_scalar()`, `validate_numeric_vector()`, `validate_positive()` |
| `detect_temporary_anomalies()` | `validate_numeric_vector()`, `validate_numeric_scalar()`, `validate_positive()` |
| `detect_time_series_anomalies()` | `validate_positive()`, `validate_numeric_scalar()` |
| `extract_quarterly_pattern()` | `validate_date_type()`, `validate_non_empty()` |
| `fetch_all_ticker_data()` | `validate_character_scalar()`, `validate_numeric_scalar()` |
| `fetch_etf_holdings()` | `validate_character_scalar()` |
| `fetch_multiple_ticker_data()` | `validate_non_empty()`, `validate_numeric_scalar()` |
| `fetch_single_financial_type()` | `validate_character_scalar()` |
| `fetch_single_ticker_data()` | `validate_character_scalar()` |
| `fetch_tickers_with_progress()` | `validate_non_empty()`, `validate_numeric_scalar()` |
| `filter_essential_financial_columns()` | `validate_df_type()` |
| `forward_fill_financial_data()` | `validate_df_cols()` |
| `generate_month_end_dates()` | `validate_month_end_date()` |
| `generate_raw_data_s3_key()` | `validate_character_scalar()` |
| `generate_s3_artifact_key()` | `validate_date_type()` |
| `generate_version_snapshot_s3_key()` | `validate_character_scalar()`, `validate_date_type()` |
| `get_api_key()` | `validate_character_scalar()` |
| `get_api_key_from_parameter_store()` | `validate_character_scalar()` |
| `get_financial_statement_tickers()` | `validate_character_scalar()` |
| `get_ticker_tracking()` | `validate_character_scalar()`, `validate_df_type()` |
| `identify_all_na_rows()` | `validate_character_scalar()` |
| `join_daily_and_financial_data()` | `validate_df_cols()` |
| `load_all_artifact_statements()` | `validate_artifact_files()` |
| `load_and_filter_financial_data()` | `validate_character_scalar()`, `validate_file_exists()`, `validate_date_type()` |
| `load_financial_artifacts()` | `validate_file_exists()` |
| `load_single_financial_type()` | `validate_character_scalar()` |
| `make_alpha_vantage_request()` | `validate_character_scalar()` |
| `parse_balance_sheet_response()` | `validate_api_response()` |
| `parse_cash_flow_response()` | `validate_api_response()` |
| `parse_earnings_response()` | `validate_api_response()` |
| `parse_etf_profile_response()` | `validate_api_response()` |
| `parse_income_statement_response()` | `validate_api_response()` |
| `parse_price_response()` | `validate_api_response()` |
| `parse_splits_response()` | `validate_api_response()` |
| `process_single_ticker()` | `validate_character_scalar()`, `validate_date_type()`, `validate_positive()`, `validate_numeric_scalar()` |
| `read_cached_data()` | `validate_file_exists()` |
| `read_cached_data_parquet()` | `validate_file_exists()` |
| `select_essential_columns()` | `validate_df_type()` |
| `set_ggplot_theme()` | `validate_positive()` |
| `should_fetch_quarterly_data()` | `validate_date_type()` |
| `s3_check_ticker_raw_data_exists()` | `validate_character_scalar()` |
| `s3_read_ticker_raw_data_single()` | `validate_character_scalar()` |
| `s3_write_refresh_tracking()` | `validate_df_type()`, `validate_character_scalar()` |
| `s3_write_ticker_raw_data()` | `validate_df_type()`, `validate_character_scalar()` |
| `s3_write_version_snapshot()` | `validate_character_scalar()` |
| `standardize_to_calendar_quarters()` | `validate_df_cols()` |
| `summarize_artifact_construction()` | `validate_df_type()` |
| `summarize_financial_data_fetch()` | `validate_character_scalar()` |
| `update_earnings_prediction()` | `validate_df_type()`, `validate_character_scalar()` |
| `update_ticker_tracking()` | `validate_df_type()`, `validate_character_scalar()` |
| `update_tracking_after_error()` | `validate_character_scalar()` |
| `upload_artifact_to_s3()` | `validate_character_scalar()`, `validate_file_exists()` |
| `validate_and_prepare_statements()` | `validate_positive()`, `validate_numeric_scalar()` |
| `validate_continuous_quarters()` | `validate_character_scalar()` |
| `validate_quarterly_continuity()` | `validate_df_cols()` |

### Functions with No Validation Required

These functions have no validation or use implicit framework validation:

| Function | Reason |
|----------|--------|
| `calculate_per_share_metrics()` | Implicit dplyr validation |
| `calculate_ttm_metrics()` | Implicit dplyr validation |
| `calculate_unified_ttm_per_share_metrics()` | Orchestrator function |
| `get_balance_sheet_metrics()` | Returns static list |
| `get_cash_flow_metrics()` | Returns static list |
| `get_financial_cache_paths()` | Returns static list |
| `get_income_statement_metrics()` | Returns static list |
| `get_spy_constituents()` | Returns static list |

### Reusable Validation Patterns

| Pattern | Status | Notes |
|---------|--------|-------|
| Character scalar validation (`validate_character_scalar()`) | ✅ DONE | |
| Numeric scalar + bounds (`validate_numeric_scalar()`, `validate_positive()`) | ✅ DONE | |
| Data frame + required columns (`validate_df_cols()`) | ✅ DONE | |
| File existence check (`validate_file_exists()`) | ✅ DONE | |
| API response error handling (`validate_api_response()`) | ✅ DONE | |
| Empty vector/list check (`validate_non_empty()`) | ✅ DONE | |
| Numeric vector validation (`validate_numeric_vector()`) | ✅ DONE | |
| Date type validation (`validate_date_type()`) | ✅ DONE | |
| **Required named list keys (`validate_list_keys()`)** | ❌ NOT IMPLEMENTED | 5 functions blocked on this (lower priority)
