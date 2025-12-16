# Housecleaning Tasks

## One Function Per File Violations

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
