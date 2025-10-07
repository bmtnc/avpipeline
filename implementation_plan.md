# Implementation Plan

[Overview]
Refactor the TTM per-share unified financial artifact script to follow declarative design principles with simple, testable helper functions.

This refactoring addresses critical code maintainability issues in `scripts/ttm_per_share_unified_financial_artifact.R`. The current implementation mixes data loading, transformation, and complex derived metric calculations inline, making it difficult to test and maintain. The refactored design will extract all inline calculations into simple, single-responsibility helper functions that are composable, testable, and self-documenting. The main script will become a readable orchestrator that describes the data pipeline declaratively, while complex business logic lives in well-tested helper functions in the `/R` directory.

This approach aligns with the project's R code style guidelines emphasizing simple functions, explicit namespace referencing, comprehensive input validation, and thorough testing. The refactoring will make the codebase more maintainable, enable better test coverage, and establish a pattern for refactoring other artifact scripts in the pipeline.

[Types]
No new type definitions are required for this refactoring.

All functions will work with standard R data types:
- `tibble`/`data.frame` objects for tabular financial data
- `numeric` vectors for financial metrics and per-share calculations
- `character` vectors for column name specifications
- `Date` objects for temporal data (already established in existing code)
- `logical` values for data quality flags

The existing column naming conventions will be maintained:
- `*_ttm` suffix for trailing twelve month metrics
- `*_per_share` suffix for per-share metrics
- `has_*` prefix for boolean data quality flags

[Files]
Files will be created and modified to extract inline logic into testable helper functions.

**New Files to Create:**

1. `R/calculate_fcf_per_share.R`
   - Extracts free cash flow per-share calculation logic
   - Single-purpose function with input validation
   
2. `R/calculate_nopat_per_share.R`
   - Extracts NOPAT (Net Operating Profit After Tax) calculation logic
   - Handles amortization extraction and tax rate application
   
3. `R/calculate_enterprise_value_per_share.R`
   - Extracts enterprise value per-share calculation logic
   - Handles debt, lease obligations, and liquid asset adjustments
   
4. `R/calculate_invested_capital_per_share.R`
   - Extracts invested capital per-share calculation logic
   - Combines debt and equity components
   
5. `R/add_derived_financial_metrics.R`
   - Orchestrator function that composes all derived metric calculations
   - Calls individual calculation functions in sequence
   
6. `R/load_financial_artifacts.R`
   - Extracts data loading logic with proper date column handling
   - Returns list of loaded artifacts
   
7. `R/join_daily_and_financial_data.R`
   - Extracts join logic for price, market cap, and financial data
   - Handles column cleanup and selection
   
8. `R/forward_fill_financial_data.R`
   - Extracts forward-fill logic for financial metrics
   - Groups by ticker and fills down
   
9. `R/select_essential_columns.R`
   - Extracts column selection logic
   - Uses helper functions to get metric lists

**Files to Modify:**

1. `scripts/ttm_per_share_unified_financial_artifact.R`
   - Replace inline calculations with function calls
   - Remove `devtools::load_all()` call (violates style guide)
   - Transform into declarative pipeline orchestrator
   - Reduce from ~150 lines to ~50 lines
   - Each step becomes a single function call

**Test Files to Create:**

1. `tests/testthat/test-calculate_fcf_per_share.R`
2. `tests/testthat/test-calculate_nopat_per_share.R`
3. `tests/testthat/test-calculate_enterprise_value_per_share.R`
4. `tests/testthat/test-calculate_invested_capital_per_share.R`
5. `tests/testthat/test-add_derived_financial_metrics.R`
6. `tests/testthat/test-load_financial_artifacts.R`
7. `tests/testthat/test-join_daily_and_financial_data.R`
8. `tests/testthat/test-forward_fill_financial_data.R`
9. `tests/testthat/test-select_essential_columns.R`

[Functions]
New functions will extract inline logic from the TTM script into testable components.

**New Functions:**

1. `calculate_fcf_per_share(operating_cf_ps, capex_ps)` in `R/calculate_fcf_per_share.R`
   - Parameters: `operating_cf_ps` (numeric), `capex_ps` (numeric)
   - Returns: numeric vector of FCF per share
   - Validation: checks both inputs are numeric
   - Logic: `operating_cf_ps - capex_ps` with NA handling
   
2. `calculate_nopat_per_share(ebit_ps, dep_amort_ps, depreciation_ps, tax_rate = 0.2375)` in `R/calculate_nopat_per_share.R`
   - Parameters: `ebit_ps` (numeric), `dep_amort_ps` (numeric), `depreciation_ps` (numeric), `tax_rate` (numeric)
   - Returns: numeric vector of NOPAT per share
   - Validation: checks all inputs are numeric, tax_rate between 0 and 1
   - Logic: Extracts amortization, applies formula `(ebit + amortization) * (1 - tax_rate)`
   
3. `calculate_enterprise_value_per_share(price, debt_total_ps, lease_obligations_ps, cash_st_investments_ps, lt_investments_ps)` in `R/calculate_enterprise_value_per_share.R`
   - Parameters: All numeric vectors
   - Returns: numeric vector of enterprise value per share
   - Validation: checks all inputs are numeric
   - Logic: `price + debt + leases - cash - investments`
   
4. `calculate_invested_capital_per_share(debt_total_ps, lease_obligations_ps, equity_ps)` in `R/calculate_invested_capital_per_share.R`
   - Parameters: All numeric vectors
   - Returns: numeric vector of invested capital per share
   - Validation: checks all inputs are numeric
   - Logic: `debt + leases + equity`
   
5. `add_derived_financial_metrics(data)` in `R/add_derived_financial_metrics.R`
   - Parameters: `data` (tibble with per-share metrics)
   - Returns: tibble with derived metrics added
   - Validation: checks required columns exist
   - Logic: Orchestrates calls to calculation functions above
   
6. `load_financial_artifacts()` in `R/load_financial_artifacts.R`
   - Parameters: None (uses fixed cache paths)
   - Returns: named list with `financial_statements`, `market_cap_data`, `price_data`
   - Validation: checks files exist before loading
   - Logic: Calls `read_cached_data()` for each artifact
   
7. `join_daily_and_financial_data(price_data, market_cap_data, ttm_data)` in `R/join_daily_and_financial_data.R`
   - Parameters: Three tibbles
   - Returns: joined tibble
   - Validation: checks required join keys exist
   - Logic: Left joins on `ticker` and `date`, drops unnecessary columns
   
8. `forward_fill_financial_data(data)` in `R/forward_fill_financial_data.R`
   - Parameters: `data` (tibble)
   - Returns: tibble with forward-filled financial data
   - Validation: checks data is data.frame
   - Logic: Groups by ticker, fills down, ungroups
   
9. `select_essential_columns(data)` in `R/select_essential_columns.R`
   - Parameters: `data` (tibble)
   - Returns: tibble with only essential columns
   - Validation: checks data is data.frame
   - Logic: Uses `get_*_metrics()` helpers to identify columns to keep

**Modified Functions:**

No existing functions require modification. The refactoring extracts new functions from inline code.

[Classes]
No new classes or modified classes are required for this refactoring.

This is a functional refactoring of procedural R code using the tidyverse paradigm. All data structures remain tibbles/data.frames processed through function pipelines.

[Dependencies]
No new package dependencies are required.

All required packages are already in the project's DESCRIPTION file:
- `dplyr` - for data manipulation
- `tidyr` - for forward filling (`tidyr::fill()`)
- `zoo` - for rolling window calculations (already used in `calculate_ttm_metrics`)
- `arrow` - for parquet file I/O (already used in main script)
- `rlang` - for non-standard evaluation (already used in `calculate_per_share_metrics`)

The refactoring uses only existing functionality in new combinations.

[Testing]
Each new helper function will have a dedicated test file with comprehensive coverage.

**Test Structure Pattern (following existing test conventions):**

Each test file will follow this structure:
1. Test valid inputs produce correct outputs
2. Test NA value handling
3. Test edge cases (zeros, negatives, empty inputs)
4. Test input validation (type checks, range checks)
5. Test error messages match expected format

**Example Test File Structure:**
```r
test_that("calculate_fcf_per_share handles valid inputs", {
  # Test with clean numeric inputs
})

test_that("calculate_fcf_per_share handles NA values", {
  # Test with NA in various positions
})

test_that("calculate_fcf_per_share validates input types", {
  # Test error handling for non-numeric inputs
})
```

**Integration Testing:**

The main script `scripts/ttm_per_share_unified_financial_artifact.R` will serve as an integration test. After refactoring, running the script should produce identical output to the current implementation (verified by comparing parquet files).

**Test Coverage Goals:**
- Each calculation function: 100% line coverage
- Each orchestrator function: Test with mock data frames
- Error paths: All validation errors tested with exact message matching

[Implementation Order]
Implementation follows a bottom-up approach: simple calculations first, then orchestrators, finally the main script.

1. **Create calculation helper functions** (no dependencies)
   - `calculate_fcf_per_share.R`
   - `calculate_nopat_per_share.R`
   - `calculate_enterprise_value_per_share.R`
   - `calculate_invested_capital_per_share.R`
   
2. **Create tests for calculation functions**
   - `test-calculate_fcf_per_share.R`
   - `test-calculate_nopat_per_share.R`
   - `test-calculate_enterprise_value_per_share.R`
   - `test-calculate_invested_capital_per_share.R`
   - Run tests to validate basic calculations
   
3. **Create orchestrator for derived metrics** (depends on step 1)
   - `add_derived_financial_metrics.R`
   - `test-add_derived_financial_metrics.R`
   - Run tests to validate composition
   
4. **Create data loading helper** (no dependencies on new functions)
   - `load_financial_artifacts.R`
   - `test-load_financial_artifacts.R`
   
5. **Create data transformation helpers** (no dependencies on new functions)
   - `join_daily_and_financial_data.R`
   - `forward_fill_financial_data.R`
   - `select_essential_columns.R`
   - Corresponding test files
   - Run tests to validate transformations
   
6. **Refactor main script** (depends on all above)
   - Modify `scripts/ttm_per_share_unified_financial_artifact.R`
   - Remove `devtools::load_all()`
   - Replace inline code with function calls
   - Test by running script and comparing output
   
7. **Validation and documentation**
   - Run full test suite with `devtools::test()`
   - Run main script and verify output matches original
   - Update roxygen documentation with `devtools::document()`
   - Verify no regressions in pipeline

This order minimizes risk by testing each component thoroughly before integration.
