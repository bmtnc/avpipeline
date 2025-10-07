# Implementation Plan: Financial Statements Artifact Refactoring

## [Overview]
Refactor `scripts/financial_statements_artifact.R` to follow declarative design principles with simple, testable helper functions.

This refactoring addresses code maintainability issues in `scripts/financial_statements_artifact.R`, a 681-line script that constructs aligned quarterly financial statements. The current implementation contains significant code duplication, particularly in sections 2.5 and 2.6 where nearly identical blocks clean anomalies for three different statement types (income statement, cash flow, balance sheet). The script also has inline logic that would benefit from extraction into testable functions for better maintainability.

The refactoring will extract repetitive logic into simple, single-responsibility helper functions using configuration-based orchestration. Similar to the successful `fetch_financial_statements.R` refactoring, this approach will eliminate duplication by looping over configuration objects instead of duplicating code blocks. The result will be a ~50-75 line main script that clearly describes the data pipeline, with all complex logic extracted to well-tested helper functions in the `/R` directory.

This refactoring follows the same pattern established in the `fetch_financial_statements.R` refactoring, applying proven design principles to maintain consistency across the codebase.

## [Types]
No new type definitions are required for this refactoring.

All functions will work with standard R data types:
- `data.frame`/`tibble` objects for financial statement data
- `character` vectors for file paths, column names, and ticker symbols
- `list` objects for configuration objects and named collections of statements
- `Date` objects for fiscal dates and calendar quarter endings
- `numeric` values for thresholds, observation counts, and window sizes
- `logical` values for validation flags

The existing configuration object structure will be maintained:
- `BALANCE_SHEET_CONFIG`, `CASH_FLOW_CONFIG`, `INCOME_STATEMENT_CONFIG`, `EARNINGS_CONFIG`
- Each contains fields like `data_type_name`, `cache_date_columns`, etc.

## [Files]
Files will be created and modified to extract repetitive logic into reusable, testable helper functions.

**New Files to Create:**

1. `R/validate_artifact_files.R`
   - Validates that required cache files exist before loading
   - Single validation function that checks all 4 artifact files
   
2. `R/load_all_artifact_statements.R`
   - Orchestrates loading all 4 financial statement artifacts
   - Returns named list with `earnings`, `cash_flow`, `income_statement`, `balance_sheet`
   
3. `R/remove_all_na_financial_observations.R`
   - Orchestrates removal of all-NA observations across all 3 statements
   - Takes named list of statements, returns cleaned named list
   
4. `R/clean_single_statement_anomalies.R`
   - Cleans one statement type using both quarterly and end-window cleaning
   - Combines sections 2.5 and 2.6 logic for a single statement
   - Parameters include statement data, metrics, and cleaning parameters
   
5. `R/clean_all_statement_anomalies.R`
   - Orchestrates anomaly cleaning for all 3 statements (excluding earnings)
   - Loops over statement configs and calls `clean_single_statement_anomalies()`
   - Returns named list with cleaned statements
   
6. `R/align_statement_tickers.R`
   - Finds tickers present in all 4 statements and filters
   - Section 3 logic extracted
   
7. `R/align_statement_dates.R`
   - Finds aligned ticker-date combinations across 3 financial statements
   - Section 4 logic extracted
   - Returns valid ticker-date combinations
   
8. `R/join_all_financial_statements.R`
   - Joins all financial statements on ticker and fiscalDateEnding
   - Section 5 logic extracted
   
9. `R/add_quality_flags.R`
   - Adds has_complete_financials, has_earnings_metadata flags
   - Section 6 logic extracted
   
10. `R/filter_essential_financial_columns.R`
    - Filters to essential columns using metric getter functions
    - Section 6.5 logic extracted
    
11. `R/validate_quarterly_continuity.R`
    - Orchestrates quarterly continuity validation across all tickers
    - Section 7 logic extracted, uses `validate_continuous_quarters()`
    
12. `R/standardize_to_calendar_quarters.R`
    - Maps fiscal dates to calendar quarter endings
    - Section 11 logic extracted
    
13. `R/create_ticker_count_plot.R`
    - Generates ticker count visualization by calendar quarter
    - Section 13 logic extracted
    
14. `R/summarize_artifact_construction.R`
    - Prints comprehensive summary of artifact construction
    - Combines sections 8, 9, and 12 summary logic

**Files to Modify:**

1. `scripts/financial_statements_artifact.R`
   - Transform into declarative pipeline orchestrator
   - Remove all code duplication (sections 2.5, 2.6, etc.)
   - Replace inline logic with function calls
   - Reduce from 681 lines to ~50-75 lines

**Test Files to Create:**

1. `tests/testthat/test-validate_artifact_files.R`
2. `tests/testthat/test-load_all_artifact_statements.R`
3. `tests/testthat/test-remove_all_na_financial_observations.R`
4. `tests/testthat/test-clean_single_statement_anomalies.R`
5. `tests/testthat/test-clean_all_statement_anomalies.R`
6. `tests/testthat/test-align_statement_tickers.R`
7. `tests/testthat/test-align_statement_dates.R`
8. `tests/testthat/test-join_all_financial_statements.R`
9. `tests/testthat/test-add_quality_flags.R`
10. `tests/testthat/test-filter_essential_financial_columns.R`
11. `tests/testthat/test-validate_quarterly_continuity.R`
12. `tests/testthat/test-standardize_to_calendar_quarters.R`
13. `tests/testthat/test-create_ticker_count_plot.R`
14. `tests/testthat/test-summarize_artifact_construction.R`

## [Functions]
New functions will extract repetitive logic and inline code into testable, reusable components.

**New Functions:**

1. `validate_artifact_files(file_paths)` in `R/validate_artifact_files.R`
   - Parameters: `file_paths` (character vector of cache file paths)
   - Returns: invisible NULL (side effect: stops on missing files)
   - Validation: Checks file_paths is character vector
   - Logic: Checks existence of all files, stops with informative message listing missing files

2. `load_all_artifact_statements()` in `R/load_all_artifact_statements.R`
   - Parameters: None (uses hardcoded cache paths)
   - Returns: named list with keys `earnings`, `cash_flow`, `income_statement`, `balance_sheet`
   - Validation: None (paths are hardcoded)
   - Logic: Calls `load_and_filter_financial_data()` for each artifact, logs counts

3. `remove_all_na_financial_observations(statements)` in `R/remove_all_na_financial_observations.R`
   - Parameters: `statements` (named list with `cash_flow`, `income_statement`, `balance_sheet`)
   - Returns: named list with cleaned versions of the 3 statements
   - Validation: Checks statements is list with required names
   - Logic: Defines metadata columns, gets financial columns for each, calls `identify_all_na_rows()`

4. `clean_single_statement_anomalies(data, metrics, statement_name, threshold, lookback, lookahead, end_window_size, end_threshold, min_obs)` in `R/clean_single_statement_anomalies.R`
   - Parameters: `data` (data.frame), `metrics` (character vector), `statement_name` (character), cleaning parameters (numeric)
   - Returns: cleaned data.frame
   - Validation: Checks all parameter types and ranges
   - Logic: Filters for sufficient obs, applies `clean_quarterly_metrics()`, then `clean_end_window_anomalies()` with error handling

5. `clean_all_statement_anomalies(statements, threshold = 4, lookback = 5, lookahead = 5, end_window_size = 5, end_threshold = 3, min_obs = 10)` in `R/clean_all_statement_anomalies.R`
   - Parameters: `statements` (named list), cleaning parameters (numeric with defaults)
   - Returns: named list with cleaned `cash_flow`, `income_statement`, `balance_sheet`
   - Validation: Checks statements structure and parameter types
   - Logic: Loops over 3 statement types, gets metrics for each, calls `clean_single_statement_anomalies()`

6. `align_statement_tickers(statements)` in `R/align_statement_tickers.R`
   - Parameters: `statements` (named list with all 4 statements)
   - Returns: named list with filtered statements (only common tickers)
   - Validation: Checks statements structure
   - Logic: Gets unique tickers from each, finds intersection, filters all statements, reports removed tickers

7. `align_statement_dates(statements)` in `R/align_statement_dates.R`
   - Parameters: `statements` (named list with `cash_flow`, `income_statement`, `balance_sheet`)
   - Returns: tibble with valid ticker-fiscalDateEnding combinations
   - Validation: Checks statements structure
   - Logic: Gets distinct ticker-date pairs, joins to find common dates, reports removed observations

8. `join_all_financial_statements(statements, valid_dates)` in `R/join_all_financial_statements.R`
   - Parameters: `statements` (named list), `valid_dates` (tibble with ticker-fiscalDateEnding)
   - Returns: joined tibble with all financial statement data
   - Validation: Checks parameter types and structure
   - Logic: Filters to valid dates, left joins earnings, inner joins other 3 statements

9. `add_quality_flags(financial_statements)` in `R/add_quality_flags.R`
   - Parameters: `financial_statements` (tibble)
   - Returns: tibble with added quality flag columns
   - Validation: Checks required columns exist
   - Logic: Uses `dplyr::if_any()` to check for data in each statement type, adds flags

10. `filter_essential_financial_columns(financial_statements)` in `R/filter_essential_financial_columns.R`
    - Parameters: `financial_statements` (tibble)
    - Returns: tibble with only essential columns
    - Validation: None (uses existing columns)
    - Logic: Gets metrics from getter functions, defines date/meta columns, selects intersection

11. `validate_quarterly_continuity(financial_statements)` in `R/validate_quarterly_continuity.R`
    - Parameters: `financial_statements` (tibble)
    - Returns: tibble with only continuous quarterly series
    - Validation: Checks required columns exist
    - Logic: Groups by ticker, uses `validate_continuous_quarters()` via split-apply-combine

12. `standardize_to_calendar_quarters(financial_statements)` in `R/standardize_to_calendar_quarters.R`
    - Parameters: `financial_statements` (tibble)
    - Returns: tibble with added `calendar_quarter_ending` column
    - Validation: Checks fiscalDateEnding column exists
    - Logic: Maps fiscal month to calendar quarter using `dplyr::case_when()`

13. `create_ticker_count_plot(financial_statements)` in `R/create_ticker_count_plot.R`
    - Parameters: `financial_statements` (tibble)
    - Returns: ggplot object
    - Validation: Checks required columns exist
    - Logic: Counts tickers by calendar quarter, creates bar chart visualization

14. `summarize_artifact_construction(original_data, final_data, removed_detail)` in `R/summarize_artifact_construction.R`
    - Parameters: `original_data` (tibble), `final_data` (tibble), `removed_detail` (tibble or NULL)
    - Returns: invisible NULL (side effect: prints summary)
    - Validation: Checks parameter types
    - Logic: Calculates and prints comprehensive construction statistics

**Modified Functions:**

No existing functions require modification. The refactoring extracts new functions from script code.

## [Classes]
No new classes or modified classes are required for this refactoring.

This is a functional refactoring of procedural R code. All data structures remain tibbles/data.frames and lists processed through function pipelines.

## [Dependencies]
No new package dependencies are required.

All required packages are already in the project's DESCRIPTION file:
- `dplyr` - for data manipulation
- `ggplot2` - for visualization
- `lubridate` - for date handling
- `zoo` - for forward-filling (used in `clean_end_window_anomalies`)

The refactoring uses only existing functionality reorganized into new function compositions.

## [Testing]
Each new helper function will have a dedicated test file with comprehensive coverage.

**Test Structure Pattern:**

Each test file will follow this structure:
1. Test valid inputs produce expected outputs
2. Test input validation (type checks, required parameters)
3. Test error messages match expected format
4. Test edge cases (empty inputs, NULL values, missing columns)

**Example Test File Structure:**
```r
test_that("validate_artifact_files succeeds with existing files", {
  # Test with valid file paths
})

test_that("validate_artifact_files stops on missing files", {
  # Test error handling for non-existent files
})

test_that("clean_single_statement_anomalies handles valid inputs", {
  # Test with mock financial data
})

test_that("clean_all_statement_anomalies validates input structure", {
  # Test error handling for invalid inputs
})
```

**Integration Testing:**

The main script `scripts/financial_statements_artifact.R` will serve as an integration test. After refactoring, running the script should produce an identical cache file to the current implementation.

**Test Coverage Goals:**
- Each helper function: 100% line coverage
- Input validation: All validation errors tested with exact message matching
- Orchestrator functions: Test with mock data to verify correct function calls
- Edge cases: Empty data, single ticker, missing columns

**Mock Testing Strategy:**

For functions that depend on file I/O or complex data:
- Use temporary directories for cache files in tests
- Create small test tibbles with minimal required columns
- Mock configuration objects for statement-specific tests
- Use `testthat::expect_error()` with regex for error message validation

## [Implementation Order]
Implementation follows a bottom-up approach: simple helpers first, then orchestrators, finally the main script.

1. **Create file validation function** (no dependencies)
   - `validate_artifact_files.R` (~15 lines)
   - `test-validate_artifact_files.R`
   - Run tests to validate

2. **Create data loading orchestrator** (depends on existing `load_and_filter_financial_data`)
   - `load_all_artifact_statements.R` (~25 lines)
   - `test-load_all_artifact_statements.R`
   - Run tests to validate

3. **Create NA removal orchestrator** (depends on existing `identify_all_na_rows`)
   - `remove_all_na_financial_observations.R` (~30 lines)
   - `test-remove_all_na_financial_observations.R`
   - Run tests to validate

4. **Create single-statement anomaly cleaner** (depends on existing cleaners)
   - `clean_single_statement_anomalies.R` (~40 lines)
   - `test-clean_single_statement_anomalies.R`
   - Run tests to validate

5. **Create all-statement anomaly cleaning orchestrator** (depends on step 4)
   - `clean_all_statement_anomalies.R` (~35 lines)
   - `test-clean_all_statement_anomalies.R`
   - Run tests to validate

6. **Create alignment functions** (no dependencies on new functions)
   - `align_statement_tickers.R` (~35 lines)
   - `test-align_statement_tickers.R`
   - `align_statement_dates.R` (~40 lines)
   - `test-align_statement_dates.R`
   - Run tests to validate

7. **Create joining and quality functions** (no dependencies on new functions)
   - `join_all_financial_statements.R` (~30 lines)
   - `test-join_all_financial_statements.R`
   - `add_quality_flags.R` (~30 lines)
   - `test-add_quality_flags.R`
   - Run tests to validate

8. **Create column filtering function** (depends on existing metric getters)
   - `filter_essential_financial_columns.R` (~25 lines)
   - `test-filter_essential_financial_columns.R`
   - Run tests to validate

9. **Create quarterly validation orchestrator** (depends on existing `validate_continuous_quarters`)
   - `validate_quarterly_continuity.R` (~30 lines)
   - `test-validate_quarterly_continuity.R`
   - Run tests to validate

10. **Create calendar quarter standardization** (no dependencies)
    - `standardize_to_calendar_quarters.R` (~25 lines)
    - `test-standardize_to_calendar_quarters.R`
    - Run tests to validate

11. **Create visualization function** (no dependencies)
    - `create_ticker_count_plot.R` (~35 lines)
    - `test-create_ticker_count_plot.R`
    - Run tests to validate

12. **Create summary function** (no dependencies)
    - `summarize_artifact_construction.R` (~40 lines)
    - `test-summarize_artifact_construction.R`
    - Run tests to validate

13. **Refactor main script** (depends on all above)
    - Modify `scripts/financial_statements_artifact.R`
    - Replace all sections with function calls
    - Create declarative pipeline
    - Reduce from 681 lines to ~50-75 lines
    - Test by running script and comparing output

14. **Validation and documentation**
    - Run full test suite with `devtools::test()`
    - Run main script and compare cache file to original
    - Use `tools::md5sum()` or manual inspection to verify equivalence
    - Update roxygen documentation with `devtools::document()`
    - Verify no regressions in downstream scripts

This order minimizes risk by testing each component thoroughly before integration and building from simplest to most complex functions.
