# Implementation Plan

[Overview]
Refactor the `fetch_financial_statements.R` script to follow declarative design principles with simple, testable helper functions.

This refactoring addresses code maintainability issues in `scripts/fetch_financial_statements.R`. The current implementation uses a configuration-based architecture but contains repetitive code blocks that duplicate the same logic four times for different financial data types. The script also violates the R code style guide by using `devtools::load_all()`. The refactored design will extract all repetitive logic into simple, single-responsibility helper functions that eliminate duplication, improve testability, and make the main script a readable orchestrator.

The main script currently contains four nearly identical blocks for fetching data (balance sheet, cash flow, income statement, earnings) and four more blocks for loading cached data. This refactoring consolidates these into loop-based orchestration functions that iterate over configurations instead of duplicating code. The result will be a ~25-line main script that clearly describes the data pipeline, with all complex logic extracted to well-tested helper functions in the `/R` directory.

This approach aligns with the project's R code style guidelines emphasizing simple functions, explicit namespace referencing, comprehensive input validation, and thorough testing. The refactoring establishes a pattern for maintaining and extending the financial data fetching pipeline.

[Types]
No new type definitions are required for this refactoring.

All functions will work with standard R data types:
- `tibble`/`data.frame` objects for financial data
- `character` vectors for ticker symbols and file paths
- `list` objects for configuration objects and named data collections
- `Date` objects for timestamps (already established in existing code)
- `numeric` values for delays and retry counts

The existing configuration object structure will be maintained:
- `BALANCE_SHEET_CONFIG`, `CASH_FLOW_CONFIG`, `INCOME_STATEMENT_CONFIG`, `EARNINGS_CONFIG`
- Each config contains fields like `data_type_name`, `cache_date_columns`, `default_delay`, etc.

[Files]
Files will be created and modified to extract repetitive logic into reusable, testable helper functions.

**New Files to Create:**

1. `R/get_financial_statement_tickers.R`
   - Extracts ticker acquisition logic with optional ETF or manual override
   - Single-purpose function for getting the list of tickers to process
   
2. `R/get_financial_cache_paths.R`
   - Extracts cache path configuration into a single source of truth
   - Returns named list of all financial statement cache file paths
   
3. `R/fetch_single_financial_type.R`
   - Extracts single data type fetching logic (e.g., just balance sheet)
   - Wrapper around `fetch_multiple_tickers_with_cache` for one config
   
4. `R/fetch_all_financial_statements.R`
   - Orchestrates fetching all 4 financial data types in a loop
   - Replaces the four duplicated fetch blocks in the main script
   
5. `R/load_single_financial_type.R`
   - Extracts single data type loading logic
   - Wrapper around `read_cached_data` for one config
   
6. `R/load_all_financial_statements.R`
   - Orchestrates loading all 4 cached financial data types
   - Replaces the four duplicated load blocks in the main script
   - Returns named list with all loaded data
   
7. `R/summarize_financial_data_fetch.R`
   - Extracts summary reporting logic
   - Generates and displays fetch statistics

**Files to Modify:**

1. `scripts/fetch_financial_statements.R`
   - Remove `devtools::load_all()` call (violates style guide)
   - Replace four fetch blocks with single `fetch_all_financial_statements()` call
   - Replace four load blocks with single `load_all_financial_statements()` call
   - Replace inline summary with `summarize_financial_data_fetch()` call
   - Transform into declarative pipeline orchestrator
   - Reduce from ~150 lines to ~25 lines

**Test Files to Create:**

1. `tests/testthat/test-get_financial_statement_tickers.R`
2. `tests/testthat/test-get_financial_cache_paths.R`
3. `tests/testthat/test-fetch_single_financial_type.R`
4. `tests/testthat/test-load_single_financial_type.R`
5. `tests/testthat/test-load_all_financial_statements.R`
6. `tests/testthat/test-summarize_financial_data_fetch.R`

Note: `fetch_all_financial_statements.R` is primarily an orchestrator and will be integration-tested via the main script.

[Functions]
New functions will extract repetitive logic from the fetch script into testable, reusable components.

**New Functions:**

1. `get_financial_statement_tickers(etf_symbol = NULL, manual_tickers = NULL)` in `R/get_financial_statement_tickers.R`
   - Parameters: `etf_symbol` (character, optional), `manual_tickers` (character vector, optional)
   - Returns: character vector of ticker symbols
   - Validation: At least one parameter must be provided; both are character type
   - Logic: If `manual_tickers` provided, use those; otherwise fetch ETF holdings
   - Logs: Number of tickers retrieved and source (ETF or manual)
   
2. `get_financial_cache_paths()` in `R/get_financial_cache_paths.R`
   - Parameters: None
   - Returns: named list with keys `balance_sheet`, `cash_flow`, `income_statement`, `earnings`
   - Validation: None (hardcoded paths)
   - Logic: Creates and returns list of cache file paths
   
3. `fetch_single_financial_type(tickers, config, cache_path)` in `R/fetch_single_financial_type.R`
   - Parameters: `tickers` (character vector), `config` (list), `cache_path` (character)
   - Returns: invisible NULL (side effect: updates cache file)
   - Validation: Checks tickers is character vector, config is list, cache_path is character
   - Logic: Logs data type name, calls `fetch_multiple_tickers_with_cache()` with appropriate functions
   
4. `fetch_all_financial_statements(tickers, cache_paths)` in `R/fetch_all_financial_statements.R`
   - Parameters: `tickers` (character vector), `cache_paths` (named list)
   - Returns: invisible NULL (side effect: updates all cache files)
   - Validation: Checks tickers is character vector, cache_paths is list with required names
   - Logic: Loops over configs (BS, CF, IS, Earnings), calls `fetch_single_financial_type()` for each
   
5. `load_single_financial_type(cache_path, config)` in `R/load_single_financial_type.R`
   - Parameters: `cache_path` (character), `config` (list)
   - Returns: tibble with loaded data
   - Validation: Checks cache_path is character, config is list
   - Logic: Calls `read_cached_data()` with config's date columns, logs row count
   
6. `load_all_financial_statements(cache_paths)` in `R/load_all_financial_statements.R`
   - Parameters: `cache_paths` (named list)
   - Returns: named list with keys `balance_sheet`, `cash_flow`, `income_statement`, `earnings`
   - Validation: Checks cache_paths is list with required names
   - Logic: Calls `load_single_financial_type()` for each config, returns named list
   
7. `summarize_financial_data_fetch(etf_symbol, tickers, data_list)` in `R/summarize_financial_data_fetch.R`
   - Parameters: `etf_symbol` (character or NULL), `tickers` (character vector), `data_list` (named list)
   - Returns: invisible NULL (side effect: prints summary)
   - Validation: Checks types, data_list has required names
   - Logic: Calculates and displays summary stats (ETF, ticker count, row counts per data type)

**Modified Functions:**

No existing functions require modification. The refactoring extracts new functions from repetitive script code.

[Classes]
No new classes or modified classes are required for this refactoring.

This is a functional refactoring of procedural R code. All data structures remain tibbles/data.frames and lists processed through function pipelines.

[Dependencies]
No new package dependencies are required.

All required packages are already in the project's DESCRIPTION file:
- `dplyr` - for data manipulation (already used extensively)
- `readr` - for CSV file I/O (already used in `read_cached_data`)

The refactoring uses only existing functionality reorganized into new function compositions.

[Testing]
Each new helper function will have a dedicated test file with comprehensive coverage.

**Test Structure Pattern:**

Each test file will follow this structure:
1. Test valid inputs produce expected outputs
2. Test input validation (type checks, required parameters)
3. Test error messages match expected format
4. Test edge cases (empty inputs, NULL values)

**Example Test File Structure:**
```r
test_that("get_financial_cache_paths returns correct structure", {
  # Test returns named list with correct keys
})

test_that("load_single_financial_type handles valid inputs", {
  # Test with mock cache file and config
})

test_that("load_single_financial_type validates input types", {
  # Test error handling for invalid inputs
})
```

**Integration Testing:**

The main script `scripts/fetch_financial_statements.R` will serve as an integration test. After refactoring, running the script should produce identical cache files to the current implementation.

**Test Coverage Goals:**
- Each helper function: 100% line coverage
- Input validation: All validation errors tested with exact message matching
- Orchestrator functions: Test with mock data to verify correct function calls

**Mock Testing Strategy:**

For functions that depend on external API calls or file I/O:
- Use temporary directories for cache files in tests
- Mock `fetch_etf_holdings()` to return test tickers
- Create small test CSV files for cache reading tests

[Implementation Order]
Implementation follows a bottom-up approach: simple helpers first, then orchestrators, finally the main script.

1. **Create simple helper functions** (no dependencies on other new functions)
   - `get_financial_cache_paths.R` (~10 lines)
   - `get_financial_statement_tickers.R` (~20 lines)
   - Create corresponding test files
   - Run tests to validate basic functionality
   
2. **Create single-type operation functions** (depend on existing functions only)
   - `fetch_single_financial_type.R` (~25 lines)
   - `load_single_financial_type.R` (~15 lines)
   - Create corresponding test files
   - Run tests to validate wrappers work correctly
   
3. **Create orchestrator functions** (depend on single-type functions)
   - `load_all_financial_statements.R` (~25 lines)
   - `test-load_all_financial_statements.R`
   - Run tests to validate multi-type orchestration
   
4. **Create fetching orchestrator** (depends on fetch_single_financial_type)
   - `fetch_all_financial_statements.R` (~30 lines)
   - This will be integration-tested via main script (difficult to unit test due to API calls)
   
5. **Create summary function** (no dependencies on new functions)
   - `summarize_financial_data_fetch.R` (~25 lines)
   - `test-summarize_financial_data_fetch.R`
   - Run tests to validate summary generation
   
6. **Refactor main script** (depends on all above)
   - Modify `scripts/fetch_financial_statements.R`
   - Remove `devtools::load_all()`
   - Replace repetitive blocks with function calls
   - Test by running script with small ticker set and comparing output
   
7. **Validation and documentation**
   - Run full test suite with `devtools::test()`
   - Run main script and verify cache files match original implementation
   - Update roxygen documentation with `devtools::document()`
   - Verify no regressions in downstream scripts that depend on cache files

This order minimizes risk by testing each component thoroughly before integration and building from simplest to most complex functions.
