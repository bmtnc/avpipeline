# Implementation Plan: Ticker-by-Ticker Pipeline Refactor

## [Overview]
Refactor the bulk financial data pipeline into a ticker-by-ticker architecture to solve memory bottlenecks while maintaining identical output. The new pipeline will fetch, clean, and process each ticker completely before moving to the next, eliminating the need to hold all ticker data in memory simultaneously.

This refactor addresses the Stage 2 memory explosion that occurs when processing 2051 tickers in AWS (IWV holdings). The current bulk approach creates 10M rows in memory and performs O(n²) operations across all grouped tickers simultaneously. The ticker-by-ticker approach processes ~5000 rows per iteration, dramatically reducing peak memory usage while maintaining algorithmic correctness.

The refactor will maximize reuse of existing functions that already operate on grouped/per-ticker data (anomaly detection, TTM calculations, forward-filling, etc.) and create minimal new wrapper functions for orchestration. The final output must be byte-for-byte identical to the existing pipeline when filtered to the same date range.

## [Types]
No new type definitions required - all data structures remain unchanged.

The pipeline continues to work with tibbles/data.frames containing:
- Financial statements: `ticker`, `fiscalDateEnding`, `reportedDate`, metric columns
- Price data: `ticker`, `date`, OHLC columns, `dividend_amount`, `split_coefficient`  
- Splits data: `ticker`, `effective_date`, `split_factor`
- Market cap: `ticker`, `date`, `post_filing_split_multiplier`, `effective_shares_outstanding`, `market_cap`
- Final artifact: all columns from current output structure

## [Files]
Create one new R function file and one new script file.

**New files to create:**
- `R/process_single_ticker.R` - Master orchestration function that runs entire pipeline for one ticker
- `scripts/build_complete_ttm_pipeline_ticker_by_ticker.R` - New main script using ticker-by-ticker loop

**Existing files to modify:**
- None - all existing functions remain unchanged and are reused as-is

**Files to reference (not modify):**
- `scripts/build_complete_ttm_pipeline.R` - Original bulk implementation (keep as reference/backup)
- All functions in `R/` directory - will be called by the new orchestration function

## [Functions]
Create one new master orchestration function.

**New function:**
- **File:** `R/process_single_ticker.R`
- **Function name:** `process_single_ticker`
- **Signature:** 
  ```r
  process_single_ticker(ticker, start_date, threshold = 4, lookback = 5, 
                       lookahead = 5, end_window_size = 5, end_threshold = 3, 
                       min_obs = 10, delay_seconds = 1)
  ```
- **Purpose:** Orchestrates all pipeline stages for a single ticker (fetch → clean → calculate → return)
- **Returns:** Tibble with complete TTM per-share data for the ticker
- **Key responsibilities:**
  1. Fetch all financial statements for ticker (balance sheet, income, cash flow, earnings)
  2. Fetch price data for ticker
  3. Fetch splits data for ticker  
  4. Clean financial statements (remove NA, detect anomalies, align dates)
  5. Join financial statements
  6. Build market cap with split adjustment
  7. Calculate TTM metrics
  8. Forward-fill financial data
  9. Calculate per-share metrics
  10. Add derived metrics
  11. Return final ticker dataset

**Existing functions to reuse (no modifications):**
- `fetch_single_ticker_data()` - fetch API data per ticker
- `remove_all_na_financial_observations()` - clean statements (works on single-ticker data)
- `clean_all_statement_anomalies()` - anomaly detection (works on single-ticker data)
- `align_statement_tickers()` - align tickers (works on single-ticker data)
- `align_statement_dates()` - align dates (works on single-ticker data)
- `join_all_financial_statements()` - join statements (works on single-ticker data)
- `add_quality_flags()` - add flags
- `filter_essential_financial_columns()` - filter columns
- `validate_quarterly_continuity()` - validate continuity
- `standardize_to_calendar_quarters()` - standardize quarters
- Market cap calculation logic from Stage 2 (extract and apply to single ticker)
- `calculate_ttm_metrics()` - TTM calculation (works on grouped data)
- `join_daily_and_financial_data()` - join datasets
- `forward_fill_financial_data()` - forward-fill (works on grouped data)
- `calculate_per_share_metrics()` - per-share division
- `select_essential_columns()` - select columns
- `add_derived_financial_metrics()` - derived metrics
- All metric getter functions
- All config objects (PRICE_CONFIG, etc.)

**Functions NOT to use:**
- `fetch_all_financial_statements()` - bulk fetcher, replaced by per-ticker calls
- `fetch_multiple_tickers_with_cache()` - bulk caching, not needed for per-ticker
- `load_all_artifact_statements()` - loads cached artifacts, not used in new flow

## [Classes]
No classes in this R codebase - uses functional programming paradigm.

## [Dependencies]
No new dependencies required.

All existing dependencies remain:
- `dplyr` - data manipulation
- `tidyr` - data tidying (fill for forward-filling)
- `arrow` - parquet I/O
- `zoo` - rolling window calculations (TTM)
- Base R functions

## [Testing]
Testing approach focuses on equivalence validation rather than unit tests.

**Validation strategy:**
1. Run new ticker-by-ticker pipeline on QQQ holdings
2. Load baseline artifact from S3: `s3://avpipeline-artifacts-prod/ttm-artifacts/2025-10-28/ttm_per_share_financial_artifact.parquet`
3. Filter both to dates before 2025-10-28 (to match baseline)
4. Use `all.equal()` to verify byte-for-byte equivalence
5. If not equal, use `dplyr::anti_join()` and comparison to identify discrepancies

**Key equivalence checks:**
- Same number of rows
- Same column names and types
- Same ticker coverage
- Same date ranges per ticker
- Same values for all metrics (within floating-point tolerance)
- Same ordering when sorted by ticker, date

**Edge cases to validate:**
- Tickers with no splits (split adjustment should still work)
- Tickers with missing financial data (should propagate NAs correctly)
- Tickers with incomplete quarters (should filter correctly)
- First few tickers vs last few tickers (ensure no state leakage)

**No unit tests required** - the user specified not to write tests, and equivalence testing provides sufficient validation

## [Implementation Order]
Step-by-step implementation sequence to ensure correctness.

1. **Create `R/process_single_ticker.R`**
   - Start with function signature and roxygen documentation
   - Implement data fetching section (financial statements, price, splits)
   - Add API delay logic (Sys.sleep between calls)
   - Implement financial statement cleaning section (reuse existing functions)
   - Implement market cap calculation section (extract from Stage 2)
   - Implement TTM calculation section (reuse existing functions)
   - Add final column ordering and selection
   - Add input validation and error handling
   - Test function standalone with single ticker (e.g., "AAPL")

2. **Create `scripts/build_complete_ttm_pipeline_ticker_by_ticker.R`**
   - Add header documentation
   - Read configuration from environment variables (ETF_SYMBOL, START_DATE)
   - Get ticker list using `get_financial_statement_tickers()`
   - Initialize empty final_artifact tibble
   - Implement main processing loop with progress messages
   - Add row binding logic
   - Add memory cleanup logic (rm(), gc() every 100 tickers)
   - Add final save logic (write_parquet)
   - Add summary statistics logging

3. **Test with small ticker subset**
   - Run with 3-5 tickers first to validate per-ticker logic
   - Check intermediate outputs for correctness
   - Verify no state leakage between tickers

4. **Run full QQQ validation**
   - Execute new pipeline on all QQQ holdings (~101 tickers)
   - Load baseline artifact from S3
   - Filter both to pre-2025-10-28 dates
   - Run all.equal() comparison
   - Investigate and fix any discrepancies

5. **Performance testing**
   - Time execution for QQQ (should complete in reasonable time)
   - Monitor memory usage (should stay bounded)
   - Verify no memory leaks between iterations

6. **Deploy configuration**
   - Update deployment scripts if needed
   - Test in AWS ECS environment with QQQ
   - Scale to IWV (2051 tickers) once validated

7. **Documentation**
   - Add comments explaining key design decisions
   - Document validation approach
   - Update README if needed

## Key Implementation Details

### Market Cap Calculation (Critical Section)
The market cap calculation from Stage 2 must be extracted exactly as-is for a single ticker:

```r
# This is the O(n²) split adjustment logic that works fine for ~5000 rows
# but fails for 10M rows in bulk processing
market_cap <- daily_shares %>%
  dplyr::left_join(prices_with_splits, by = c("ticker", "date")) %>%
  dplyr::group_by(ticker) %>%
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
      commonStockSharesOutstanding * dplyr::coalesce(post_filing_split_multiplier, 1),
    market_cap = dplyr::if_else(
      has_financial_data,
      close * effective_shares_outstanding / 1e6,
      NA_real_
    )
  )
```

### Error Handling Strategy
- Wrap entire `process_single_ticker()` call in tryCatch
- If one ticker fails, log error and continue to next ticker
- Track failed tickers in a separate list
- Report summary at end (successful vs failed counts)
- Do not let one bad ticker crash entire pipeline

### Memory Management
- Use `rm()` to remove ticker-specific objects after binding to final artifact
- Call `gc()` every 100 tickers to force garbage collection
- Monitor memory growth during execution
- Final artifact grows linearly (acceptable)

### Progress Tracking
- Log clear progress messages: "Processing AAPL (1/101)"
- Log stage completion: "✓ AAPL complete (5234 rows)"
- Log failures: "✗ AAPL failed: <error message>"
- Log overall summary at end

### Validation Approach
Use exact comparison, not tolerance-based:
```r
baseline <- arrow::read_parquet("s3://...") %>%
  dplyr::filter(date < as.Date("2025-10-28")) %>%
  dplyr::arrange(ticker, date)

new_result <- final_artifact %>%
  dplyr::filter(date < as.Date("2025-10-28")) %>%
  dplyr::arrange(ticker, date)

all.equal(baseline, new_result)
```

If not equal, investigate with:
```r
dplyr::anti_join(baseline, new_result, by = c("ticker", "date"))
dplyr::anti_join(new_result, baseline, by = c("ticker", "date"))
