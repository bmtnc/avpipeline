# Function Usage Analysis - avpipeline R Package

**Last Updated:** 2026-01-20
**Total R Files:** 117 (down from 144 after cleanup)
**Cleanup Performed:** Removed 27 unused/legacy files

---

## Production Pipelines

The avpipeline package has **two production pipelines**:

### 1. Local Pipeline
`scripts/build_complete_ttm_pipeline_ticker_by_ticker.R`
- Simple ticker-by-ticker processing
- No tracking system
- Outputs to local `cache/` directory

### 2. AWS Pipeline (Two-Phase)
- **Phase 1**: `scripts/run_phase1_fetch.R` - Fetches raw data to S3 with smart refresh
- **Phase 2**: `scripts/run_phase2_generate.R` - Generates TTM artifacts from S3 raw data
- Uses full tracking system
- Outputs to S3

---

## Parser Functions - IMPORTANT NOTE

**Parser functions ARE actively used** via dynamic calling in `fetch_single_ticker_data.R`:

```r
parser_func_name <- config$parser_func
parser_func <- get(parser_func_name)  # Dynamic call!
parsed_data <- parser_func(response, ticker)
```

All parsers are called based on the `parser_func` field in each config object:
- `parse_price_response` - via PRICE_CONFIG
- `parse_balance_sheet_response` - via BALANCE_SHEET_CONFIG
- `parse_income_statement_response` - via INCOME_STATEMENT_CONFIG
- `parse_cash_flow_response` - via CASH_FLOW_CONFIG
- `parse_earnings_response` - via EARNINGS_CONFIG
- `parse_splits_response` - via SPLITS_CONFIG
- `parse_etf_profile_response` - via ETF_PROFILE_CONFIG

---

## Cleanup Summary (2026-01-20)

### Deleted Legacy Scripts (8 files)
- `scripts/price_artifact.R`
- `scripts/splits_artifact.R`
- `scripts/financial_statements_artifact.R`
- `scripts/market_cap_artifact.R`
- `scripts/ttm_per_share_unified_financial_artifact.R`
- `scripts/build_complete_ttm_pipeline.R`
- `scripts/validate_refactor.R`
- `scripts/explore_ttm_artifact.R`

### Deleted Unused R Functions (8 files)
- `R/fetch_multiple_ticker_data.R` - superseded by ticker-by-ticker
- `R/fetch_tickers_with_progress.R` - only called by fetch_multiple_ticker_data
- `R/combine_ticker_results.R` - only called by fetch_multiple_ticker_data
- `R/get_spy_constituents.R` - static list, no callers
- `R/load_and_filter_financial_data.R` - helper with no callers
- `R/log_data_discrepancy.R` - monitoring utility, no callers
- `R/s3_check_ticker_raw_data_exists.R` - AWS utility, no callers
- `R/parse_overview_response.R` - parser for removed OVERVIEW_CONFIG

### Deleted Monitoring Utilities (3 files)
- `R/detect_data_changes.R` - no production callers
- `R/detect_data_loss.R` - no production callers
- `R/validate_quarterly_consistency.R` - only called by deleted functions

### Deleted Legacy-Script-Only Functions (15 files)
- `R/fetch_multiple_tickers_with_cache.R`
- `R/fetch_single_financial_type.R`
- `R/fetch_all_financial_statements.R`
- `R/load_all_financial_statements.R`
- `R/load_all_artifact_statements.R`
- `R/load_financial_artifacts.R`
- `R/load_single_financial_type.R`
- `R/read_cached_data.R`
- `R/read_cached_data_parquet.R`
- `R/get_financial_cache_paths.R`
- `R/create_ticker_count_plot.R`
- `R/set_ggplot_theme.R`
- `R/summarize_artifact_construction.R`
- `R/summarize_financial_data_fetch.R`
- `R/validate_artifact_files.R`

### Additional Deletions
- `R/should_fetch_overview_data.R` - referenced deleted config
- Removed `OVERVIEW_CONFIG` from `alpha_vantage_configs.R`
- Removed `DATA_TYPE_REFRESH_CONFIG` from `alpha_vantage_configs.R`

---

## Local Pipeline Call Graph

```
build_complete_ttm_pipeline_ticker_by_ticker.R
├── get_financial_statement_tickers()
├── fetch_etf_holdings()
└── process_single_ticker() [MAIN ORCHESTRATOR]
    ├── fetch_all_ticker_data()
    │   ├── fetch_single_ticker_data()
    │   │   ├── make_alpha_vantage_request()
    │   │   └── get_api_key()
    │   └── Parsers (called dynamically via config):
    │       parse_price_response(), parse_balance_sheet_response(),
    │       parse_income_statement_response(), parse_cash_flow_response(),
    │       parse_earnings_response(), parse_splits_response()
    │
    ├── validate_and_prepare_statements()
    │   ├── remove_all_na_financial_observations()
    │   │   └── identify_all_na_rows()
    │   ├── clean_all_statement_anomalies()
    │   │   └── clean_single_statement_anomalies()
    │   │       ├── filter_sufficient_observations()
    │   │       ├── clean_quarterly_metrics()
    │   │       │   ├── add_anomaly_flag_columns()
    │   │       │   │   └── detect_temporary_anomalies()
    │   │       │   │       └── detect_single_baseline_anomaly()
    │   │       │   │           ├── calculate_baseline()
    │   │       │   │           ├── calculate_baseline_stats()
    │   │       │   │           └── detect_baseline_anomaly()
    │   │       │   └── clean_original_columns()
    │   │       └── clean_end_window_anomalies()
    │   │           └── detect_time_series_anomalies()
    │   ├── align_statement_tickers()
    │   ├── align_statement_dates()
    │   ├── join_all_financial_statements()
    │   ├── add_quality_flags()
    │   ├── filter_essential_financial_columns()
    │   ├── validate_quarterly_continuity()
    │   │   └── validate_continuous_quarters()
    │   └── standardize_to_calendar_quarters()
    │
    ├── build_market_cap_with_splits()
    │
    └── calculate_unified_ttm_per_share_metrics()
        ├── get_income_statement_metrics()
        ├── get_cash_flow_metrics()
        ├── get_balance_sheet_metrics()
        ├── calculate_ttm_metrics()
        ├── join_daily_and_financial_data()
        ├── forward_fill_financial_data()
        ├── calculate_per_share_metrics()
        ├── select_essential_columns()
        └── add_derived_financial_metrics()
            ├── calculate_fcf_per_share()
            ├── calculate_nopat_per_share()
            ├── calculate_enterprise_value_per_share()
            └── calculate_invested_capital_per_share()
```

---

## AWS Pipeline Call Graph

### Phase 1: run_phase1_fetch.R
```
run_phase1_fetch.R
├── Logging: log_phase_start(), log_phase_end(), log_pipeline(),
│            log_progress_summary(), log_failed_tickers()
├── get_api_key_from_parameter_store()
├── s3_read_refresh_tracking(), s3_write_refresh_tracking()
├── get_financial_statement_tickers()
├── s3_list_existing_tickers()
├── Checkpointing: s3_read_checkpoint(), s3_write_checkpoint(),
│                  s3_clear_checkpoint(), update_checkpoint()
├── create_pipeline_log(), add_log_entry()
├── get_ticker_tracking()
├── determine_fetch_requirements()
│   └── should_fetch_quarterly_data()
├── fetch_and_store_ticker_data()
│   └── fetch_and_store_single_data_type()
│       ├── fetch_single_ticker_data()
│       │   ├── make_alpha_vantage_request()
│       │   └── Parsers (dynamic)
│       └── s3_write_ticker_raw_data()
├── update_tracking_after_fetch(), update_tracking_after_error()
└── update_earnings_prediction()
    └── calculate_next_estimated_report_date()
        └── calculate_median_report_delay()
```

### Phase 2: run_phase2_generate.R
```
run_phase2_generate.R
├── Logging: log_phase_start(), log_phase_end(), log_pipeline()
├── s3_load_all_raw_data() [Arrow dataset loading]
├── process_ticker_from_s3() [PARALLEL - mclapply]
│   ├── validate_and_prepare_statements()
│   │   └── [Same cleaning/alignment as local pipeline]
│   ├── build_market_cap_with_splits()
│   └── calculate_unified_ttm_per_share_metrics()
│       └── [Same TTM calculations as local pipeline]
└── upload_artifact_to_s3()
```

---

## Functions Used by msdataviz (Public API)

These functions are exported for use by the msdataviz project:
- `get_latest_price_artifact()` - S3 artifact retrieval
- `get_latest_ttm_artifact()` - S3 artifact retrieval
- `validate_df_cols()` - input validation
- `validate_character_scalar()` - input validation
- `validate_non_empty()` - input validation
- `calculate_nopat_per_share()` (internal, via `:::`)
- `calculate_invested_capital_per_share()` (internal, via `:::`)
- `calculate_enterprise_value_per_share()` (internal, via `:::`)

---

## Function Categories

### Anomaly Detection (ACTIVELY USED)
These functions form the data cleaning pipeline and ARE used in production:
- `detect_time_series_anomalies()` - Master detection function
- `detect_baseline_anomaly()` - Persistent shift detection
- `detect_single_baseline_anomaly()` - Single metric anomaly detection
- `detect_temporary_anomalies()` - Temporary spike detection
- `calculate_baseline()` - Baseline calculation
- `calculate_baseline_stats()` - Baseline statistics
- `add_anomaly_flag_columns()` - Add flags to data
- `clean_end_window_anomalies()` - End-of-series handling
- `clean_quarterly_metrics()` - Clean quarterly data
- `clean_single_statement_anomalies()` - Per-statement cleaning
- `clean_all_statement_anomalies()` - All statements cleaning
- `clean_original_columns()` - Column cleanup

### Data Fetching
- `fetch_single_ticker_data()` - Core single-ticker fetcher
- `fetch_all_ticker_data()` - Fetch all data types for ticker
- `fetch_and_store_ticker_data()` - Fetch and store to S3
- `fetch_and_store_single_data_type()` - Single type to S3
- `fetch_etf_holdings()` - Get ETF constituent tickers
- `make_alpha_vantage_request()` - Raw API request

### Parsing (ALL USED via dynamic calling)
- `parse_price_response()`
- `parse_balance_sheet_response()`
- `parse_income_statement_response()`
- `parse_cash_flow_response()`
- `parse_earnings_response()`
- `parse_splits_response()`
- `parse_etf_profile_response()`

### Statement Processing
- `validate_and_prepare_statements()` - Main orchestrator
- `remove_all_na_financial_observations()`
- `identify_all_na_rows()`
- `align_statement_tickers()`
- `align_statement_dates()`
- `join_all_financial_statements()`
- `add_quality_flags()`
- `filter_essential_financial_columns()`
- `validate_quarterly_continuity()`
- `validate_continuous_quarters()`
- `standardize_to_calendar_quarters()`

### TTM Calculations
- `calculate_unified_ttm_per_share_metrics()` - Main orchestrator
- `calculate_ttm_metrics()` - Rolling 4-quarter sum
- `calculate_per_share_metrics()` - Divide by shares
- `join_daily_and_financial_data()`
- `forward_fill_financial_data()`
- `select_essential_columns()`
- `get_income_statement_metrics()`
- `get_cash_flow_metrics()`
- `get_balance_sheet_metrics()`

### Derived Metrics
- `add_derived_financial_metrics()` - Orchestrator
- `calculate_fcf_per_share()`
- `calculate_nopat_per_share()`
- `calculate_invested_capital_per_share()`
- `calculate_enterprise_value_per_share()`

### Tracking System (AWS Pipeline)
- `create_empty_refresh_tracking()`
- `create_default_ticker_tracking()`
- `get_ticker_tracking()`
- `update_ticker_tracking()`
- `update_tracking_after_fetch()`
- `update_tracking_after_error()`
- `update_earnings_prediction()`
- `calculate_next_estimated_report_date()`
- `calculate_median_report_delay()`
- `determine_fetch_requirements()`
- `should_fetch_quarterly_data()`

### S3 Operations
- `s3_read_refresh_tracking()`
- `s3_write_refresh_tracking()`
- `s3_read_ticker_raw_data()`
- `s3_read_ticker_raw_data_single()`
- `s3_write_ticker_raw_data()`
- `s3_write_version_snapshot()`
- `s3_list_existing_tickers()`
- `upload_artifact_to_s3()`
- `generate_raw_data_s3_key()`
- `generate_s3_artifact_key()`
- `generate_version_snapshot_s3_key()`

### Validation Utilities
- `validate_df_cols()`
- `validate_df_type()`
- `validate_character_scalar()`
- `validate_non_empty()`
- `validate_date_type()`
- `validate_file_exists()`
- `validate_api_response()`
- `validate_month_end_date()`

### Miscellaneous
- `build_market_cap_with_splits()`
- `process_single_ticker()` - Local pipeline orchestrator
- `process_ticker_from_s3()` - AWS phase 2 processor
- `get_api_key()`
- `get_api_key_from_parameter_store()`
- `get_financial_statement_tickers()`
- `get_config_for_data_type()`
- `with_timeout()`
- `with_retry()`
- `send_pipeline_notification()`

---

## Architecture Notes

1. **Configuration-driven design**: All data types use config objects in `alpha_vantage_configs.R`
2. **Dynamic parser calling**: Parsers are called via `get(config$parser_func)` - not direct calls
3. **Ticker-by-ticker processing**: Memory-bounded architecture for large ETF processing
4. **Two-phase AWS pipeline**: Separation of fetch (Phase 1) and generate (Phase 2)
5. **Tracking system**: Smart refresh logic to minimize API calls
