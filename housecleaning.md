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

## Validations (COMPLETED)

All functions below have been refactored to use reusable validation helper functions.

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

### Functions Refactored

The following functions have been updated to use the validation helpers:

| Function | Boilerplate Validations |
|----------|------------------------|
| `add_anomaly_flag_columns()` | char vector validation, df validation, numeric bounds (threshold, lookback, lookahead) |
| `add_derived_financial_metrics()` | required columns check |
| `add_quality_flags()` | data frame type check |
| `align_statement_dates()` | list type check, required named elements validation |
| `align_statement_tickers()` | list type check, required named elements validation |
| `build_market_cap_with_splits()` | Date type, length check (scalar), bounds check (start_date >= threshold) |
| `calculate_baseline()` | numeric type, length checks (scalars), bounds checks (positive values), cross-parameter validation |
| `calculate_baseline_stats()` | numeric type check, numeric vector validation, bounds checks |
| `calculate_enterprise_value_per_share()` | numeric type checks (5x: price, debt, lease, cash, lt_investments) |
| `calculate_fcf_per_share()` | numeric type checks (operating_cf_ps, capex_ps) |
| `calculate_invested_capital_per_share()` | numeric type checks (debt, lease, equity per share) |
| `calculate_median_report_delay()` | required columns check, sufficient observations, NA handling |
| `calculate_next_estimated_report_date()` | NA check (last_fiscal_date_ending) |
| `calculate_nopat_per_share()` | numeric type checks (5x), bounds check (tax_rate 0-1) |
| `calculate_per_share_metrics()` | implicit validation only |
| `calculate_ttm_metrics()` | implicit dplyr validation only |
| `calculate_unified_ttm_per_share_metrics()` | implicit orchestrator validation |
| `clean_all_statement_anomalies()` | list type, required names (cash_flow, income, balance), numeric bounds (threshold > 0) |
| `clean_end_window_anomalies()` | char vector validation, df validation, numeric bounds (3x: end_window_size, threshold, min_observations) |
| `clean_original_columns()` | char vector validation (non-empty), required columns check |
| `clean_quarterly_metrics()` | char vector validation (2x: metric_cols, date_col, ticker_col), df validation, numeric bounds (3x: threshold, lookback, lookahead) |
| `combine_ticker_results()` | missing param check, list/char/list type checks (3x), required names validation (2x), empty checks |
| `create_ticker_count_plot()` | required columns check |
| `detect_baseline_anomaly()` | numeric type, length checks (scalar), NA checks, threshold bounds check, baseline MAD validity |
| `detect_data_changes()` | df type check, char validation, column existence check, null/empty check |
| `detect_data_loss()` | null/empty check, df type check, column existence check |
| `detect_single_baseline_anomaly()` | numeric type (3x), length checks (scalar), empty vector check, bounds (3x), cross-param validation (index range) |
| `detect_temporary_anomalies()` | numeric vector validation, empty check, numeric scalar validations (3x), bounds checks (3x), length requirement |
| `detect_time_series_anomalies()` | numeric type, scalar validation, bounds (threshold > 0, min_obs > 0), empty/NA checks, length requirement |
| `determine_missing_symbols()` | empty vector check, null/empty data check, column existence |
| `extract_quarterly_pattern()` | Date class check, scalar validation, non-empty check, logical ordering, membership check |
| `fetch_all_financial_statements()` | char vector type, list type, named list keys validation |
| `fetch_all_ticker_data()` | char scalar validation, numeric scalar validation, bounds check (non-negative delay) |
| `fetch_etf_holdings()` | char scalar validation (non-empty, nchar check) |
| `fetch_multiple_ticker_data()` | char vector validation, non-empty check, list type, numeric bounds (delay) |
| `fetch_multiple_tickers_with_cache()` | non-empty check, missing param checks (3x) |
| `fetch_single_financial_type()` | char vector type, list type, char scalar validation (cache_path) |
| `fetch_single_ticker_data()` | missing param check, char scalar validation, list type, named list element check (parser_func) |
| `fetch_tickers_with_progress()` | missing param check, char vector validation, list type, named element check (data_type_name), numeric bounds |
| `filter_essential_financial_columns()` | data frame type check |
| `filter_sufficient_observations()` | char scalar validation, required columns, numeric bounds (min_obs > 0), NA check |
| `forward_fill_financial_data()` | df type check, required columns check |
| `generate_month_end_dates()` | month-end date validation (delegated), logical ordering (start_date <= end_date) |
| `generate_raw_data_s3_key()` | char scalar validations (2x: ticker, data_type) |
| `generate_s3_artifact_key()` | Date class type check |
| `generate_version_snapshot_s3_key()` | char scalar validations (2x: ticker, data_type), Date class check |
| `get_api_key()` | char type check, length check (scalar), non-empty check (nzchar) |
| `get_api_key_from_parameter_store()` | char scalar validations (2x: param_name, region), exit status check, non-empty result |
| `get_balance_sheet_metrics()` | no validation |
| `get_cash_flow_metrics()` | no validation |
| `get_financial_cache_paths()` | no validation |
| `get_financial_statement_tickers()` | null check (at least one param), char scalar (etf_symbol), char vector (manual_tickers) |
| `get_income_statement_metrics()` | no validation |
| `get_spy_constituents()` | no validation |
| `get_ticker_tracking()` | char scalar validation, df type check |
| `identify_all_na_rows()` | char vector type, char scalar validation, non-empty check, df validation |
| `join_all_financial_statements()` | list type check, required columns check |
| `join_daily_and_financial_data()` | df type checks (3x), required columns checks (3x) |
| `load_all_artifact_statements()` | file existence check (delegated to utility) |
| `load_all_financial_statements()` | list type check, required names validation |
| `load_and_filter_financial_data()` | char scalar validation, file existence check, Date type check, required columns, post-filter empty check |
| `load_financial_artifacts()` | file existence checks (3x with similar pattern) |
| `load_single_financial_type()` | char scalar validation, list type check |
| `make_alpha_vantage_request()` | char scalar presence check, list type check, required keys validation (2x) |
| `parse_balance_sheet_response()` | API error checks, API note check, required response key, null/empty check |
| `parse_cash_flow_response()` | API error checks, API note check, required response key, null/empty check |
| `parse_earnings_response()` | API error checks, missing key checks, null/empty checks, string-to-NA conversion |
| `parse_etf_profile_response()` | API error checks, missing key checks, empty checks, missing column checks, NA filtering |
| `parse_income_statement_response()` | API error checks, missing key check, null/empty checks, string-to-NA conversion, numeric coercion |
| `parse_price_response()` | API error checks, missing time series key, datatype param validation |
| `parse_splits_response()` | JSON structure type check, API error checks, null/empty checks, column validation, string-to-NA conversion |
| `process_single_ticker()` | char validation (ticker), Date validation (start_date), numeric bounds (threshold, delay_seconds), minimal data checks |
| `read_cached_data()` | file existence check, conditional column presence check |
| `read_cached_data_parquet()` | file existence check, file extension validation, package availability check (requireNamespace), error wrapping |
| `remove_all_na_financial_observations()` | list type check, required named elements validation |
| `select_essential_columns()` | df type check |
| `set_ggplot_theme()` | numeric scalar positivity checks (4x: repeated identical pattern) |
| `should_fetch_quarterly_data()` | Date type check |
| `s3_check_ticker_raw_data_exists()` | char scalar validations (ticker, bucket_name) |
| `s3_read_ticker_raw_data_single()` | char scalar validations (3x: ticker, data_type, bucket_name), system call status check |
| `s3_write_refresh_tracking()` | df type check, char scalar validation (bucket_name) |
| `s3_write_ticker_raw_data()` | df type check, char scalar validations (3x: ticker, data_type, bucket_name) |
| `s3_write_version_snapshot()` | char scalar validations (2x: ticker, data_type), null data check |
| `standardize_to_calendar_quarters()` | required columns check |
| `summarize_artifact_construction()` | df type checks (3x), optional df-or-null check |
| `summarize_financial_data_fetch()` | optional char scalar check, char vector type, list type, required names validation |
| `update_earnings_prediction()` | df type checks (2x), char scalar validation, empty result check |
| `update_ticker_tracking()` | df type check, char scalar validation, list type check |
| `update_tracking_after_error()` | char scalar validation |
| `upload_artifact_to_s3()` | char scalar validations (4x: repeated pattern), file existence check |
| `validate_and_prepare_statements()` | numeric scalar positivity, numeric scalar non-negativity checks (2x) |
| `validate_artifact_files()` | char vector type, file existence checks |
| `validate_continuous_quarters()` | char scalar validation, char vector type, required columns, NA/missing value handling |
| `validate_df_cols()` | char vector type, df type check, required columns check |
| `validate_df_type()` | df type check |
| `validate_month_end_date()` | Date type check, scalar length check, business logic validation (month-end) |
| `validate_quarterly_consistency()` | null/empty check, df type check, row bounds check, required columns, column name existence |
| `validate_quarterly_continuity()` | df type check, required columns check |

### Reusable Validation Patterns (ALL IMPLEMENTED)

All validation patterns have been extracted and implemented:

- ~~**Character scalar validation** (`validate_character_scalar()`)~~: DONE
- ~~**Numeric scalar + bounds validation** (`validate_numeric_scalar()`, `validate_positive()`)~~: DONE
- ~~**Data frame + required columns** (`validate_df_cols()`)~~: DONE
- **Required named list keys** (`validate_list_keys()`): NOT IMPLEMENTED (8+ occurrences - lower priority)
- ~~**File existence check** (`validate_file_exists()`)~~: DONE
- ~~**API response error handling** (`validate_api_response()`)~~: DONE
- ~~**Empty vector/list check** (`validate_non_empty()`)~~: DONE
- ~~**Numeric vector validation** (`validate_numeric_vector()`)~~: DONE
- ~~**Date type validation** (`validate_date_type()`)~~: DONE
