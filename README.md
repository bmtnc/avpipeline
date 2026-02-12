# avpipeline

<!-- badges: start -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.0.0.9000-blue.svg)](https://github.com/bmtnc/avpipeline)
<!-- badges: end -->

An R package that implements a two-phase ETL pipeline for Alpha Vantage financial data. The pipeline fetches stock prices, income statements, balance sheets, cash flows, earnings, and splits for all tickers in an ETF, then processes them into quarterly TTM (trailing twelve months) financial metrics. A separate on-demand function joins quarterly financials with daily prices to produce a daily-frequency per-share artifact.

## Architecture Overview

The pipeline runs in two phases on AWS (ECS Fargate, weekly on Sundays):

**Phase 1 — Fetch** (`run_phase1_fetch.R`): Downloads raw data from Alpha Vantage API and stores per-ticker parquet files in S3. Processes tickers sequentially (1 API request/sec). Smart refresh logic skips quarterly re-fetches unless near predicted earnings or data is >90 days stale.

**Phase 2 — Generate** (`run_phase2_generate.R`): Loads all raw data from S3, processes each ticker in parallel (anomaly detection, statement alignment, TTM calculations), and uploads two artifacts: `ttm_quarterly_artifact.parquet` and `price_artifact.parquet`.

**On-demand — Daily Artifact** (`create_daily_ttm_artifact()`): Joins quarterly TTM data with daily prices locally. Forward-fills financials from `reportedDate`, calculates market cap with split adjustments, and computes per-share metrics.

```
Phase 1 (AWS, sequential)          Phase 2 (AWS, parallel)           On-demand (local)
Alpha Vantage API                   S3 raw data                       S3 artifacts
  → fetch per ticker                  → clean & validate                → join quarterly + price
  → store to S3                       → anomaly detection               → forward-fill financials
  → update tracking                   → TTM calculations                → market cap + splits
                                      → upload artifacts                → per-share metrics
```

## Features

- **Smart Quarterly Refresh**: Only re-fetches quarterly data when near predicted earnings (±5 days) or >90 days stale, saving ~4 API calls per ticker most weeks
- **Checkpoint Recovery**: Phase 1 saves progress every 25 tickers; interrupted runs resume from last checkpoint
- **Parallel Processing**: Phase 2 uses all available cores via `parallel::mclapply()`
- **Anomaly Detection**: Z-score based detection on quarterly financial metrics (MAD with configurable threshold)
- **Retry Logic**: API requests retry up to 3 times with exponential backoff (5s, 10s) for rate limits and timeouts
- **Error Isolation**: One bad ticker doesn't crash the pipeline; failures are logged and skipped
- **Refresh Tracking**: Per-ticker state (last fetch dates, earnings predictions, errors) persisted in S3

## Installation

```r
# Install from GitHub
# install.packages("devtools")
devtools::install_github("bmtnc/avpipeline")
```

## Quick Start

### 1. Set up your Alpha Vantage API key

```r
# Set environment variable
Sys.setenv(ALPHA_VANTAGE_API_KEY = "your_api_key_here")
```

### 2. Get ETF holdings

```r
library(avpipeline)

# Fetch ticker list for an ETF
holdings <- fetch_etf_holdings("IWV")
```

### 3. Load pipeline artifacts

```r
# Load the latest artifacts from S3
quarterly <- load_quarterly_artifact(bucket = "avpipeline-artifacts-prod")
prices <- load_price_artifact(bucket = "avpipeline-artifacts-prod")

# Create the daily per-share artifact on-demand
daily <- create_daily_ttm_artifact(quarterly, prices)
```

### 4. Process a single ticker from S3

```r
# Process one ticker's raw S3 data into a daily TTM artifact
result <- process_ticker_from_s3("AAPL", bucket = "avpipeline-artifacts-prod")
```

### 5. Add tickers on-demand

Fetch, process, and merge new tickers into the latest S3 artifacts without running the full pipeline:

```r
add_tickers_to_artifact(
  c("PLTR", "COIN", "TSM", "BABA"),
  bucket_name = "avpipeline-artifacts-prod",
  fetch = TRUE   # FALSE to skip API fetch if raw data already in S3
)
```

This runs Phase 1 (fetch from Alpha Vantage) and Phase 2 (process + merge) for the specified tickers only, updating the quarterly and price artifacts in S3.

### 6. Build implied volatility term structures

Fetch historical option chains and build IV term structure artifacts for a basket of tickers:

```r
# Fetch 12 weeks of options data, build IV term structures, upload to S3
fetch_options_and_build_artifact(
  c("AAPL", "MSFT", "SPY"),
  n_weeks = 12,
  bucket_name = "avpipeline-artifacts-prod"
)

# Load the artifacts
raw_ts <- load_options_raw_term_structure("avpipeline-artifacts-prod")
interp_ts <- load_options_interpolated_term_structure("avpipeline-artifacts-prod")

# Pivot interpolated term structure to wide format
tidyr::pivot_wider(interp_ts, names_from = tenor_days, values_from = iv, names_prefix = "iv_")
```

Works with any ticker — price data is automatically fetched from Alpha Vantage and stored in S3 if not already present.

## AWS Deployment

The avpipeline can be deployed to AWS for automated weekly execution with artifact storage in S3.

### Quick Deployment

```bash
# From project root
bash deploy/setup.sh
```

This automated script will:
- Deploy infrastructure using Terraform (ECS Fargate, Step Functions, S3, SNS, ECR, CloudWatch, Parameter Store)
- Build and push Docker container to ECR
- Set up weekly scheduling (Sundays at 2am ET via EventBridge → Step Functions)
- Configure email notifications and failure alarms

### Architecture

- **Step Functions**: Orchestrates Phase 1 → Phase 2 sequencing with 8-hour timeouts per phase and automatic retry (2 attempts, exponential backoff)
- **ECS Fargate**: Serverless container execution. Phase 1 runs on 4 vCPU / 8GB (batch API + parallel S3 writes); Phase 2 runs on 4 vCPU / 8GB for parallel processing
- **S3**: Artifact storage with lifecycle policies — TTM artifacts expire after 30 days, raw data after 365 days
- **EventBridge**: Weekly scheduling (Sundays at 2am ET triggers the Step Functions state machine)
- **CloudWatch**: Alarms on Step Functions execution failures and timeouts, both notify via SNS
- **SNS**: Email notifications for pipeline success/failure/alarms
- **Parameter Store**: Secure API key storage

### Configuration

Phase 1 supports a `FETCH_MODE` environment variable to control what gets fetched:
- `full` (default) — price, splits, and quarterly data (subject to smart refresh logic)
- `price_only` — only daily prices and splits
- `quarterly_only` — only quarterly financials (balance sheet, income, cash flow, earnings)

Phase 2 supports a `PHASE2_MODE` environment variable to control processing:
- `incremental` (default) — only reprocess tickers updated in Phase 1, merge with previous artifact
- `full` — reprocess all tickers from scratch (use after code changes to anomaly detection or TTM logic)

### Cost

Approximately **$5-8/month** for weekly runs (Phase 2 uses 4 vCPU / 8GB).

### Full Documentation

See [deploy/README.md](deploy/README.md) for:
- Prerequisites and setup instructions
- Manual deployment steps
- Testing and monitoring
- Configuration options
- Troubleshooting guide

## Pipeline Architecture

### Two-Phase Design

The production pipeline splits fetching and processing into separate phases. This enables Phase 1 to run sequentially (API-bound) while Phase 2 runs in parallel (CPU-bound), and allows either phase to be re-run independently.

### Phase 1: Fetch Raw Data

Iterates through all tickers sequentially, fetching data from Alpha Vantage and storing per-ticker parquet files in S3.

**Per-ticker flow:**
1. `determine_fetch_requirements()` — checks tracking state to decide what to fetch
2. `fetch_and_store_ticker_data()` — orchestrates fetching the required data types
3. Each data type calls `fetch_and_store_single_data_type()`:
   - `fetch_price()` → `make_av_request()` → `parse_price_response()`
   - `fetch_splits()` → `make_av_request()` → `parse_splits_response()`
   - `fetch_balance_sheet()` → `make_av_request()` → `parse_balance_sheet_response()`
   - `fetch_income_statement()` → `make_av_request()` → `parse_income_statement_response()`
   - `fetch_cash_flow()` → `make_av_request()` → `parse_cash_flow_response()`
   - `fetch_earnings()` → `make_av_request()` → `parse_earnings_response()`
4. Each successful fetch writes to `s3://bucket/raw/{TICKER}/{data_type}.parquet`
5. Update refresh tracking (last fetch dates, earnings predictions)

**End-of-run**: After all tickers are processed, Phase 1 writes a manifest (`s3://{bucket}/raw/_metadata/phase1_manifest.parquet`) listing all successfully updated tickers and their data types. This manifest drives incremental Phase 2 processing.

**Smart refresh**: Price and splits are fetched every run. Quarterly data (balance sheet, income, cash flow, earnings) is only fetched when `should_fetch_quarterly_data()` returns TRUE:
- New ticker (never fetched) → fetch
- Data >90 days stale → fetch
- Within ±5 days of predicted earnings → fetch
- Otherwise → skip

### Phase 2: Generate Artifacts

Supports two modes via `PHASE2_MODE` environment variable:
- `incremental` (default) — only reprocess tickers updated in Phase 1, merge unchanged rows from previous artifact
- `full` — reprocess all tickers from scratch

**Incremental mode flow:**
1. Read Phase 1 manifest (`s3://{bucket}/raw/_metadata/phase1_manifest.parquet`) listing tickers updated this run
2. Load previous `ttm_quarterly_artifact.parquet` from S3
3. Determine reprocess set: manifest tickers (updated) + tickers in S3 but not in previous artifact (new). Tickers in previous artifact but no longer in S3 are dropped. All others carry forward unchanged.
4. Sync all raw data from S3 via `aws s3 sync`, load into memory, then filter to reprocess tickers only for quarterly processing
5. Process reprocess tickers in parallel, merge with unchanged rows from previous artifact
6. Price artifact is always fully rebuilt (cheap — just filter + write)

Falls back to full reprocess if no manifest or no previous artifact exists.

**Per-ticker flow** (via `process_ticker_for_quarterly_artifact()`):
1. `validate_and_prepare_statements()` — clean, detect anomalies, align dates, join statements
2. `calculate_ttm_metrics()` — rolling 4-quarter sum for flow metrics (income + cash flow)
3. Return quarterly-frequency TTM tibble

**Outputs uploaded to S3:**
- `ttm_quarterly_artifact.parquet` — quarterly TTM financials for all tickers
- `price_artifact.parquet` — cleaned daily prices for all tickers

**Performance (~2,100 tickers on 4 vCPU / 8GB Fargate, full mode ~33 min):**
- S3 sync + local loading: ~2 min — `aws s3 sync` to local disk, then parallel `arrow::read_parquet()` from local files
- Pre-split by ticker: ~2 sec (skip price, pre-split remaining 6 data types for O(1) lookups in parallel workers)
- Per-ticker processing: ~30 min — anomaly detection, statement alignment, and TTM calculations are genuinely compute-bound

**Incremental mode** reduces the ~30 min processing phase proportionally to the reprocess set. On a typical weekly run with ~100-200 updated tickers (out of ~2,100), processing drops to ~2-3 min, bringing total Phase 2 from ~33 min to ~5-6 min. S3 sync and price artifact rebuild remain unchanged.

### On-Demand: Daily Artifact

`create_daily_ttm_artifact()` runs locally to produce the final daily-frequency dataset:
1. Join quarterly financials with daily prices using `reportedDate`
2. Forward-fill financials until next earnings announcement
3. Build market cap with split adjustments (`build_market_cap_with_splits()`)
4. Calculate per-share metrics (TTM per-share for flow metrics, point-in-time per-share for balance sheet)

### On-Demand: Options IV Term Structure

`fetch_options_and_build_artifact()` runs locally to fetch historical option chains and build implied volatility term structures. Designed for on-demand use with small-to-medium baskets of tickers (not scheduled AWS runs). All functions are exported for use by other packages.

**Per-ticker flow:**
1. Load daily prices from S3 (auto-fetches from Alpha Vantage if missing)
2. `derive_weekly_dates()` — derive N weekly observation dates from daily prices
3. Incremental fetch: compare weekly dates against existing options data in S3, fetch only missing dates via `HISTORICAL_OPTIONS` endpoint (one API call per date, each returning the full option chain)
4. `build_options_term_structure()` — for each observation date:
   - `extract_atm_options()` — find at-the-money options (within 5% moneyness) per expiration
   - `calculate_iv_term_structure()` — average call/put ATM IV per expiration, compute days-to-expiration
   - `interpolate_iv_to_standard_tenors()` — linear interpolation to 30d, 60d, 90d, 180d, 365d tenors

**S3 storage:**
- Raw option chains: `raw/{TICKER}/historical_options.parquet` (one file per ticker, all dates concatenated, deduped on `contractID + date`)
- Raw term structure artifact: `options-artifacts/{YYYY-MM-DD}/raw_term_structure.parquet` (one row per ticker/observation_date/expiration)
- Interpolated term structure artifact: `options-artifacts/{YYYY-MM-DD}/interpolated_term_structure.parquet` (one row per ticker/observation_date/tenor)

**Artifact snapshots:** Each run writes a fresh artifact containing only the tickers from that run — it does not merge with a previous artifact. Pass all desired tickers in a single call. Raw option chains in `raw/{TICKER}/historical_options.parquet` are always preserved and appended to incrementally regardless.

**API volume:** Each API call returns the full chain for one ticker on one date. At 1 req/sec: 12 weeks × 1 ticker = ~12 sec; 52 weeks × 10 tickers = ~9 min. Incremental fetch skips dates already in S3.

**Performance (IWV, ~2,100 tickers):**
- **Phase 1 (Fetch)**: ~1.3 hours (~3.2 sec/ticker avg, httr2 batch processing with `req_throttle`, CSV price format)
- **Phase 2 (Generate)**: ~33 min (parallelized across all cores, S3 sync for data loading)
- **Total**: ~1.9 hours end-to-end
- **Memory usage**: Constant ~500MB
- **API rate**: 1 request/sec via `req_throttle` (stays under 75 req/min premium limit)

**Production scripts:**
- `scripts/run_pipeline_aws.R` — Top-level orchestrator (sources Phase 1 then Phase 2)
- `scripts/run_phase1_fetch.R` — Phase 1 implementation
- `scripts/run_phase2_generate.R` — Phase 2 implementation
- `scripts/run_phase1_aws.R` / `scripts/run_phase2_aws.R` — AWS wrappers with notifications

## Core Functions

### API Layer (internal)
- **`make_av_request()`**: Universal HTTP request handler with `with_retry()` for exponential backoff
- **`fetch_price()`**, **`fetch_balance_sheet()`**, **`fetch_income_statement()`**, **`fetch_cash_flow()`**, **`fetch_earnings()`**, **`fetch_splits()`**: Per-data-type fetch functions
- **`fetch_etf_holdings()`**: Fetch ETF constituent tickers (exported)

### Parsers (8 total)
- **`parse_price_response()`**: Daily adjusted price data
- **`parse_balance_sheet_response()`**: Quarterly balance sheets
- **`parse_income_statement_response()`**: Quarterly income statements
- **`parse_cash_flow_response()`**: Quarterly cash flows
- **`parse_earnings_response()`**: Earnings timing metadata
- **`parse_splits_response()`**: Stock split events
- **`parse_etf_profile_response()`**: ETF holdings and profile
- **`parse_historical_options_response()`**: Historical option chains (exported)

### Pipeline Orchestration
- **`fetch_and_store_ticker_data()`**: Orchestrates all fetches for one ticker based on requirements
- **`fetch_and_store_single_data_type()`**: Fetches one data type and writes to S3
- **`determine_fetch_requirements()`**: Decides what to fetch based on tracking state
- **`should_fetch_quarterly_data()`**: Earnings-aware conditional fetch logic
- **`process_ticker_for_quarterly_artifact()`**: Phase 2 per-ticker processing

### Data Processing
- **`validate_and_prepare_statements()`**: Master function for cleaning and aligning financial statements
- **`calculate_ttm_metrics()`**: Rolling 4-quarter TTM calculations for flow metrics
- **`create_daily_ttm_artifact()`**: On-demand daily artifact generation (exported)
- **`build_market_cap_with_splits()`**: Daily market cap with split adjustments

### Options & IV Term Structure (exported)
- **`fetch_options_and_build_artifact()`**: Primary entry point — fetches option chains, builds IV term structures, uploads artifacts to S3
- **`build_options_term_structure()`**: Builds raw + interpolated term structures for one ticker across all observation dates
- **`calculate_iv_term_structure()`**: Calculates ATM IV term structure for one observation date
- **`interpolate_iv_to_standard_tenors()`**: Linear interpolation to standard tenors (30d, 60d, 90d, 180d, 365d)
- **`derive_weekly_dates()`**: Derives weekly observation dates from daily price data
- **`load_options_raw_term_structure()`**, **`load_options_interpolated_term_structure()`**: Load options artifacts from S3

### Anomaly Detection
- **`detect_time_series_anomalies()`**: Master anomaly detection function
- **`detect_temporary_anomalies()`**: Detects temporary spikes/drops
- **`detect_single_baseline_anomaly()`**: Baseline anomaly detection for single position
- **`detect_baseline_anomaly()`**: Persistent baseline shift detection
- **`clean_end_window_anomalies()`**: End-of-series anomaly handling
- Parameters: `threshold = 4`, `lookback = 5`, `lookahead = 5`

### Validation
- **`validate_df_cols()`**, **`validate_df_type()`**: DataFrame validation
- **`validate_quarterly_continuity()`**: Ensure continuous quarters exist
- **`validate_continuous_quarters()`**: Quarter-by-quarter continuity checks
- **`validate_character_scalar()`**, **`validate_numeric_scalar()`**, **`validate_numeric_vector()`**, **`validate_positive()`**, **`validate_non_empty()`**, **`validate_date_type()`**, **`validate_file_exists()`**, **`validate_month_end_date()`**: Input validators

### Artifact Loaders (exported)
- **`load_quarterly_artifact()`**, **`load_price_artifact()`**, **`load_daily_ttm_artifact()`**: Load TTM artifacts from S3
- **`load_options_raw_term_structure()`**, **`load_options_interpolated_term_structure()`**: Load options IV artifacts from S3
- **`get_latest_ttm_artifact()`**, **`get_latest_price_artifact()`**: Get latest artifact paths

## API Key Management

```r
# Method 1: Environment variable (recommended for local development)
Sys.setenv(ALPHA_VANTAGE_API_KEY = "your_key_here")

# Method 2: AWS Parameter Store (used in production)
# Key is stored at /avpipeline/alpha-vantage-api-key
# Retrieved automatically by run_phase1_fetch.R via get_api_key_from_parameter_store()
```

## Retry Logic

API requests use exponential backoff via `with_retry()` in `make_av_request()`:
- **3 attempts** maximum
- **5-second** initial delay, **2x** multiplier (5s → 10s → 20s)
- Only retries on rate limits, timeouts, and connection errors
- Non-retryable errors (invalid ticker, missing data) fail immediately

## Rate Limiting

All API calls use a uniform **1-second delay** between requests (configurable via `API_DELAY_SECONDS` environment variable). At 6 endpoints per ticker, this means ~6 seconds per ticker for full fetches, ~2 seconds for price+splits only.

## Development Status

**Current Version**: 0.0.0.9000 (Development)

### Implemented Features
- Two-phase S3 pipeline (fetch + generate)
- Incremental Phase 2 processing (reprocess only updated tickers, merge with previous artifact)
- Smart quarterly refresh based on earnings predictions
- Checkpoint recovery for interrupted runs
- Parallel Phase 2 processing
- All 7 parser functions
- Anomaly detection on quarterly financial metrics
- TTM calculations and per-share metrics
- Market cap with split adjustments
- On-demand daily artifact generation
- Comprehensive validation and error handling
- AWS deployment (ECS Fargate, S3, EventBridge, SNS)

### Known Issues

**Stock splits cause stale shares outstanding for up to 90 days.** When a stock split occurs between quarterly data fetches, the pipeline produces incorrect market cap and per-share metrics until the next quarterly refetch. This was observed with $NOW's 5-for-1 split in December 2025.

Root cause: `should_fetch_quarterly_data()` only re-fetches quarterly data when near predicted earnings (±5 days) or when data is >90 days stale. Stock splits trigger Alpha Vantage to retroactively adjust `commonStockSharesOutstanding` in their balance sheet API, but the pipeline doesn't re-fetch quarterly data when a split is detected. Meanwhile, Phase 1 does re-fetch price data every run, so `split_coefficient` and `adjusted_close` update immediately. This creates a mismatch: split-adjusted prices paired with pre-split shares outstanding.

The fix would be to detect splits in Phase 1 (via price data `split_coefficient` or the SPLITS endpoint) and force a quarterly data refetch for affected tickers.

Relevant files:
- `R/should_fetch_quarterly_data.R` - conditional quarterly fetch logic
- `R/determine_fetch_requirements.R` - fetch requirements per ticker
- `R/build_market_cap_with_splits.R` - market cap calculation using splits

**~12% of tickers fail Phase 1 every run (non-destructive).** As of Feb 2026, 257 of 2,115 IWV tickers consistently fail during Phase 1 fetch. The same tickers fail across runs. Breakdown:

| Error | Count | Cause |
|-------|-------|-------|
| `Expected 'Time Series (Daily)' key not found` | 204 | AV returns unexpected response structure (no price data) |
| `No quarterly reports/earnings found` | 36 | AV has price data but no financial statements |
| `Invalid API call` | 17 | AV explicitly rejects the ticker symbol |

These are tickers AV doesn't cover: delisted/merged companies still in the ETF universe (e.g., WBA post-acquisition), special share classes, or newly listed companies. **Failures are non-destructive** — the pipeline records the error in `last_error_message` in refresh tracking but does not overwrite existing S3 data from prior successful fetches. Phase 2 processes whatever raw data exists in S3 regardless of Phase 1 outcome (2,027 of 2,034 tickers succeeded in Phase 2 on Feb 8).

### Phase 1 Performance Optimization on Fargate

Phase 1 was optimized from 10.8 sec/ticker down to 3.2 sec/ticker on Fargate (4 vCPU / 8GB) through a series of iterative changes. The final breakthrough was switching price data from JSON to CSV format, which eliminated the response parsing bottleneck that had been misattributed to S3 write latency for most of the optimization effort.

**Timeline of optimization attempts (Feb 2026):**

| Change | Local (sec/ticker) | AWS (sec/ticker) | Notes |
|--------|-------------------|-----------------|-------|
| Baseline (sequential httr + Sys.sleep) | — | 10.8 | Original implementation |
| httr2 batch (`req_perform_parallel` + `req_throttle`) | 5.3 | 9.3 | API calls decoupled from S3, but S3 writes still sequential |
| + Parallel S3 writes (`mclapply`, mc.cores=10) | 3.9 | 8.1 | Expected big win; minimal improvement on AWS |
| + Arrow native S3 (`arrow::write_parquet(s3_uri)`) | 3.9 | 8.1 | Eliminated temp file + AWS CLI process spawn per write |
| + Bumped Phase 1 to 4 vCPU / 8GB | 3.9 | 7.8 | Gave mclapply real cores; barely helped |
| + Single `S3FileSystem` (no mclapply) | 3.9 | 6.9 | Pre-initialized S3 connection, sequential writes through it |
| + Local write + `aws s3 cp --recursive` | 2.5 | 5.9 | Write parquet to local disk, batch upload via CLI parallel transfers |
| + Pipelined S3 sync (`mcparallel`) | 2.5 | 6.7 | Background sync during next batch's API calls; no improvement |
| + CSV format for price data | — | 3.2 | 48x faster parsing; eliminated the post-API bottleneck |

**What we tried and why we thought it would work:**

1. **httr2 batch processing** (`req_perform_parallel` + `req_throttle`): The original Phase 1 loop called `Sys.sleep(1)` between API requests, during which S3 writes from the previous ticker blocked. Batching API requests via `req_perform_parallel` with `req_throttle(capacity=1, fill_time_s=1)` decouples API pacing from S3 writes. This worked — API calls now fire at exactly 1/sec regardless of S3 write speed. But S3 writes were still sequential within the batch processing phase.

2. **Parallel S3 writes via `mclapply`**: After all API responses return, we have ~58 independent S3 writes per batch. Running them in parallel via `parallel::mclapply(mc.cores=10)` should overlap network I/O. Locally this worked well (3.9 sec/ticker). On Fargate with 1 vCPU, the forked processes time-sliced rather than running in parallel, yielding no improvement.

3. **Arrow native S3 writes**: The original S3 write path was: `arrow::write_parquet(data, temp_file)` → `system2("aws", c("s3", "cp", temp_file, s3_uri))`. Each write spawned a Python process (AWS CLI) with ~2-3 sec overhead. Switching to `arrow::write_parquet(data, "s3://...")` eliminated the temp file and process spawn. This should have been a significant win per-write, but the overall batch timing barely changed.

4. **4 vCPU for Phase 1**: Increased from 1 vCPU / 4GB to 4 vCPU / 8GB to give `mclapply` real parallelism. Expected the S3 write phase to drop from ~140 sec to ~20 sec. Actual improvement was marginal (~7.8 vs 8.1 sec/ticker), suggesting the bottleneck isn't CPU contention.

5. **Single pre-initialized `S3FileSystem`**: Hypothesis was that `mclapply` fork overhead + per-process Arrow S3 initialization + credential resolution from ECS metadata service dominated write time. Fix: create one `arrow::S3FileSystem$create()` and write all files sequentially through it. One credential resolution, one connection, 58 fast PUTs. Expected ~6 sec for all writes. Actual improvement: 7.8 → 6.9 sec/ticker — modest.

6. **Local write + `aws s3 cp --recursive`**: Instead of writing each parquet file directly to S3, write all files to a local temp directory first (milliseconds), then upload the entire directory in one `aws s3 cp --recursive` call. The AWS CLI performs parallel transfers internally (10 concurrent by default), turning 58 sequential S3 PUTs into a single parallelized batch upload. This was the first approach to meaningfully improve AWS performance: 6.9 → 5.9 sec/ticker.

7. **Pipelined S3 sync via `mcparallel`**: Hypothesis: the ~90-sec gap between the API progress bar hitting 100% and the next batch starting was dominated by S3 uploads. If we kicked off `aws s3 cp --recursive` as a background process (via `parallel::mcparallel`) and immediately started the next batch's API calls, the S3 upload time would be hidden behind the next batch's ~60-sec API phase. Expected: ~2.5 sec/ticker. Actual: 6.7 sec/ticker — no improvement. The gap after the progress bar is dominated by **response parsing** (JSON deserialization + type conversion for thousands of rows per ticker), not S3 uploads. The S3 sync was already a small fraction of the post-bar time; hiding it saved nothing.

8. **CSV format for price data**: The price endpoint was being requested as JSON and parsed via `jsonlite::fromJSON()` + `lapply()` over ~6,000 date keys, creating one `data.frame` per date then `bind_rows()`. This was the dominant cost in the ~90-sec post-API gap. The root cause is structural: Alpha Vantage's JSON nests each date as a key with 8 field names repeated per row (`"1. open"`, `"2. high"`, etc.), inflating the response to 2.3MB — over half of which is redundant key names. The R parsing then compounds this by allocating a `data.frame()` per date (6,000 allocations with type validation and row-name creation each) before binding them together. CSV avoids both problems: the response is 498KB (4.5x smaller, no repeated field names), and `read.csv()` is a single call into optimized C code that reads the entire table in one pass. The quarterly endpoints (balance sheet, earnings, etc.) don't suffer from this because they're ~80 rows with flat array structure that `fromJSON()` handles efficiently — price was the outlier at 6,000 rows of deeply nested JSON. Alpha Vantage supports `datatype=csv` for the price endpoint, and `parse_price_response()` already had a CSV code path. The fix was one line: changing `datatype = "json"` to `datatype = "csv"` in `build_batch_requests.R`. Local benchmarks showed **48.5x faster parsing** (31ms vs 1,505ms per ticker). On AWS, the post-API gap dropped from ~90 sec to ~4 sec per batch, bringing overall performance from 5.9 to **3.2 sec/ticker**.

**Analysis:**

For a batch of 25 tickers with ~78 API requests (full fetch):
- API calls: ~78 sec (hard floor at 1 req/sec, identical local and AWS)
- Response parsing: ~4 sec (CSV for price, JSON for small quarterly endpoints)
- S3 uploads: ~20 sec (via `aws s3 cp --recursive` parallel transfers)
- Checkpoint/tracking saves: ~6 sec (2× `system2("aws s3 cp")`)

The theoretical floor is ~78 sec / 25 tickers = 3.1 sec/ticker. At 3.2 sec/ticker, Phase 1 is now operating near its API rate limit floor. The earlier attempts (1-7) were optimizing S3 writes when the real bottleneck was JSON parsing of the price endpoint's ~6,000-row nested response. Once parsing was fixed via CSV format, S3 write optimizations became irrelevant — the entire post-API phase takes ~30 sec vs the ~78-sec API phase.

**Current performance (IWV, ~2,100 tickers):**
- Phase 1: ~1.3 hours at 3.2 sec/ticker (down from 6.3 hours at 10.8 sec/ticker)
- Phase 2: ~33 min (down from 44 min via S3 sync optimization)
- Total: ~1.9 hours end-to-end

### Phase 2 Performance Optimization on Fargate

Phase 2 was optimized from 44 min down to 33 min by replacing ~14,000 individual S3 GET requests with a single `aws s3 sync` to local disk.

The original `s3_load_all_raw_data()` read each parquet file individually via `arrow::read_parquet("s3://...")` — one HTTP request per file (2,100 tickers × 7 data types). Each S3 GET incurs ~50-100ms of latency overhead (connection setup, TLS handshake, request routing). Even parallelized across 7 data types via `mclapply`, each worker still read ~2,100 files sequentially.

The fix: `aws s3 sync s3://bucket/raw/ /tmp/raw/` downloads the entire raw directory to local disk using the AWS CLI's built-in parallel transfers (10 concurrent by default), then `arrow::read_parquet()` reads from local files with zero network latency. The sync also excludes `_versions/` and `_metadata/` directories to avoid downloading unnecessary data.

| Phase | Before | After | Improvement |
|-------|--------|-------|-------------|
| S3 data loading | ~11 min (14K individual GETs) | ~2 min (sync + local reads) | ~9 min saved |
| Pre-split by ticker | ~5 sec (split all 7 data types) | ~1.6 sec (skip price, largest dataset) | ~3 sec saved |
| Per-ticker processing | ~30 min | ~30 min (unchanged) | — |
| **Total Phase 2** | **~44 min** | **~33 min** | **25% faster** |

**Potential future approaches (not yet attempted):**
- Reduce per-ticker data volume by requesting `outputsize=compact` for weekly refreshes
- Run Phase 1 on EC2 instead of Fargate (to rule out container networking/CPU overhead)

Relevant Phase 1 files:
- `R/process_batch_responses.R` — batch response processing with S3 writes
- `R/s3_write_ticker_raw_data.R` — Arrow native S3 write
- `R/build_batch_requests.R` — batch request construction
- `R/build_av_request.R` — httr2 request builder with `req_throttle`
- `scripts/run_phase1_fetch.R` — Phase 1 batch loop
- `deploy/terraform/variables.tf` — Fargate CPU/memory configuration

Relevant Phase 2 files:
- `R/s3_load_all_raw_data.R` — S3 sync + local parquet reads
- `R/determine_phase2_reprocess_set.R` — incremental reprocess set logic
- `R/derive_phase1_manifest.R` — manifest derivation from pipeline log
- `R/s3_write_phase1_manifest.R` / `R/s3_read_phase1_manifest.R` — manifest S3 I/O
- `R/load_raw_data_for_tickers.R` — selective local parquet loading (currently unused; retained for future use)
- `scripts/run_phase2_generate.R` — Phase 2 batch processing loop (incremental/full modes)

### Next Steps
- Fix split-triggered quarterly refetch (see Known Issues above)
- Package validation and documentation updates

## Contributing

This package follows standard R package development practices:

1. Use `renv` for dependency management
2. Follow tidyverse style guidelines
3. Include comprehensive documentation
4. Add tests for new functionality

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Alpha Vantage API

This package requires an Alpha Vantage API key. Get your free API key at [Alpha Vantage](https://www.alphavantage.co/support/#api-key).

### API Endpoints Used
- `TIME_SERIES_DAILY_ADJUSTED` - Daily price data
- `INCOME_STATEMENT` - Quarterly income statement data
- `BALANCE_SHEET` - Quarterly balance sheet data
- `CASH_FLOW` - Quarterly cash flow data
- `EARNINGS` - Quarterly earnings timing metadata
- `SPLITS` - Stock splits data
- `ETF_PROFILE` - ETF holdings and profile data
- `HISTORICAL_OPTIONS` - Historical option chains with IV and Greeks

---

**Disclaimer**: This package is not affiliated with Alpha Vantage. Please review Alpha Vantage's terms of service before using their API.

## ttm_per_share_financial_artifact.csv

**Daily frequency dataset** that bridges quarterly financial reporting with daily market data by mapping financial metrics to actual earnings announcement dates.

**Core Design:**
- **Frequency:** Daily observations (long-form)
- **Index:** `ticker` and `date`
- **Key Innovation:** Quarterly financial statements mapped to `date` based on actual earnings announcement dates (`reportedDate`), then forward-filled to create daily frequency

**Date Column Usage:**
- **`date`** - Primary column for daily frequency analysis, synchronized with daily prices
- **`fiscalDateEnding`** - Use for quarterly frequency analysis of financial KPIs only

**Contents:**
- **Market data:** Daily prices, volume, dividends, splits
- **Share metrics:** `commonStockSharesOutstanding`, `effective_shares_outstanding`, `market_cap`
- **Financial metrics (per-share basis):**
  - **Flow metrics:** Income statement & cash flow items converted to TTM per-share (e.g., `fcf_ttm_per_share`, `ebitda_ttm_per_share`)
  - **Balance sheet metrics:** Point-in-time per-share values (e.g., `totalAssets_per_share`, `tangible_book_value_per_share`)

**Key Features:**
- Quarterly financial data forward-filled until next earnings announcement
- Ready for daily time-series analysis of fundamental metrics
- Enables creation of daily frequency fundamental ratios and screens
- Maintains quarterly granularity via `fiscalDateEnding` for period-specific analysis

**Primary Use Case:** Daily frequency fundamental analysis, bridging the gap between quarterly earnings cycles and daily market movements.

## Function Dependency Tree

Function call graph rooted at each entry point script. Where a subtree has already been fully shown, `(see above)` avoids repetition.

### scripts/run_pipeline_aws.R

Top-level AWS orchestrator. Sources Phase 1 and Phase 2, then sends notifications.

```
scripts/run_pipeline_aws.R
├── source("run_phase1_fetch.R")        → (see scripts/run_phase1_fetch.R)
├── source("run_phase2_generate.R")     → (see scripts/run_phase2_generate.R)
├── send_pipeline_notification
├── create_pipeline_log
├── upload_pipeline_log
│   └── upload_artifact_to_s3
│       ├── validate_character_scalar
│       ├── validate_file_exists
│       ├── system2_with_timeout
│       │   ├── validate_character_scalar
│       │   ├── validate_positive → validate_numeric_scalar
│       │   └── with_timeout
│       └── is_timeout_result
└── generate_s3_artifact_key
    └── validate_date_type
```

### scripts/run_phase1_fetch.R

Phase 1: Fetches raw data from Alpha Vantage API and stores per-ticker in S3.

```
scripts/run_phase1_fetch.R
├── log_phase_start / log_phase_end / log_pipeline / log_progress_summary / log_failed_tickers
├── get_api_key_from_parameter_store
│   ├── validate_character_scalar
│   ├── system2_with_timeout (see above)
│   └── is_timeout_result
├── s3_read_refresh_tracking
│   ├── system2_with_timeout (see above)
│   ├── is_timeout_result
│   ├── with_timeout
│   └── initialize_tracking_from_s3_data
│       ├── s3_list_existing_tickers
│       │   ├── system2_with_timeout (see above)
│       │   └── is_timeout_result
│       ├── s3_read_ticker_raw_data_single
│       │   ├── generate_raw_data_s3_key → validate_character_scalar
│       │   └── validate_character_scalar
│       ├── extract_tracking_from_ticker_data
│       │   └── create_default_ticker_tracking
│       └── create_empty_refresh_tracking
├── get_financial_statement_tickers
│   ├── validate_character_scalar
│   └── fetch_etf_holdings
│       ├── validate_character_scalar
│       ├── make_av_request → get_api_key, with_retry, validate_character_scalar
│       └── parse_etf_profile_response → validate_api_response
├── s3_list_existing_tickers (see above)
├── s3_read_checkpoint → validate_character_scalar, system2_with_timeout, is_timeout_result, with_timeout
├── create_pipeline_log
├── get_ticker_tracking → validate_character_scalar, validate_df_type, create_default_ticker_tracking
├── determine_fetch_requirements
│   └── should_fetch_quarterly_data → validate_date_type
├── fetch_and_store_ticker_data
│   ├── determine_fetch_requirements (see above)
│   ├── fetch_and_store_single_data_type
│   │   ├── fetch_balance_sheet  → make_av_request → parse_balance_sheet_response  → validate_api_response
│   │   ├── fetch_income_statement → make_av_request → parse_income_statement_response → validate_api_response
│   │   ├── fetch_cash_flow     → make_av_request → parse_cash_flow_response     → validate_api_response
│   │   ├── fetch_earnings      → make_av_request → parse_earnings_response      → validate_api_response
│   │   ├── fetch_price         → make_av_request, get_api_key → parse_price_response → validate_api_response
│   │   ├── fetch_splits        → make_av_request → parse_splits_response        → validate_api_response
│   │   ├── s3_write_ticker_raw_data
│   │   │   ├── generate_raw_data_s3_key (see above)
│   │   │   ├── validate_character_scalar, validate_df_type
│   │   │   └── upload_artifact_to_s3 (see above)
│   │   └── s3_write_version_snapshot
│   │       ├── generate_version_snapshot_s3_key → validate_character_scalar, validate_date_type
│   │       ├── s3_read_ticker_raw_data_single (see above)
│   │       └── upload_artifact_to_s3 (see above)
│   └── update_tracking_after_fetch
│       └── update_ticker_tracking → validate_df_type, create_default_ticker_tracking
├── update_tracking_after_error → update_ticker_tracking (see above)
├── update_earnings_prediction
│   ├── validate_character_scalar, validate_df_type
│   ├── calculate_median_report_delay → validate_df_cols → validate_df_type
│   ├── calculate_next_estimated_report_date
│   └── update_ticker_tracking (see above)
├── add_log_entry
├── update_checkpoint → create_empty_checkpoint
├── s3_write_checkpoint → validate_character_scalar, system2_with_timeout, is_timeout_result
├── s3_write_refresh_tracking → validate_df_type, validate_character_scalar, upload_artifact_to_s3 (see above)
├── s3_write_phase1_manifest
│   ├── validate_df_type, validate_character_scalar
│   ├── derive_phase1_manifest → validate_df_type
│   └── upload_artifact_to_s3 (see above)
└── s3_clear_checkpoint → validate_character_scalar, system2_with_timeout, is_timeout_result
```

### scripts/run_phase2_generate.R

Phase 2: Loads raw data from S3, processes each ticker for quarterly TTM metrics, uploads artifacts.

```
scripts/run_phase2_generate.R
├── log_phase_start / log_phase_end / log_pipeline
├── [incremental mode]
│   ├── s3_read_phase1_manifest → validate_character_scalar, arrow::read_parquet
│   ├── s3_list_existing_tickers (see above)
│   ├── load_quarterly_artifact → get_latest_ttm_artifact, arrow::read_parquet
│   └── determine_phase2_reprocess_set
├── s3_load_all_raw_data
│   ├── s3_list_existing_tickers (see above)
│   └── log_pipeline
├── process_ticker_for_quarterly_artifact
│   ├── validate_character_scalar
│   ├── validate_and_prepare_statements
│   │   ├── remove_all_na_financial_observations
│   │   │   └── identify_all_na_rows → validate_df_cols, validate_character_scalar
│   │   ├── clean_all_statement_anomalies
│   │   │   ├── validate_positive → validate_numeric_scalar
│   │   │   └── clean_single_statement_anomalies
│   │   │       ├── validate_df_cols
│   │   │       ├── filter_sufficient_observations → validate_non_empty, validate_df_cols
│   │   │       └── clean_quarterly_metrics
│   │   │           ├── validate_df_cols, validate_df_type, validate_character_scalar
│   │   │           ├── validate_non_empty, validate_positive, validate_numeric_scalar
│   │   │           ├── add_anomaly_flag_columns
│   │   │           │   ├── validate_df_cols, validate_non_empty, validate_positive
│   │   │           │   ├── detect_temporary_anomalies
│   │   │           │   │   ├── validate_numeric_vector, validate_positive, validate_numeric_scalar
│   │   │           │   │   └── detect_single_baseline_anomaly
│   │   │           │   │       ├── validate_numeric_vector, validate_positive, validate_numeric_scalar
│   │   │           │   │       ├── calculate_baseline → validate_positive, validate_numeric_scalar
│   │   │           │   │       └── calculate_baseline_stats → validate_numeric_vector
│   │   │           │   └── detect_baseline_anomaly → validate_positive
│   │   │           └── clean_original_columns → validate_df_cols, validate_non_empty
│   │   ├── align_statement_tickers
│   │   ├── filter_essential_financial_columns
│   │   │   ├── validate_df_type
│   │   │   ├── get_income_statement_metrics
│   │   │   ├── get_cash_flow_metrics
│   │   │   └── get_balance_sheet_metrics
│   │   ├── align_statement_dates
│   │   ├── join_all_financial_statements → validate_df_cols
│   │   ├── validate_quarterly_continuity
│   │   │   ├── validate_df_cols
│   │   │   └── validate_continuous_quarters
│   │   │       ├── validate_character_scalar
│   │   │       ├── extract_quarterly_pattern
│   │   │       │   ├── validate_non_empty, validate_date_type
│   │   │       │   └── generate_month_end_dates → validate_month_end_date
│   │   │       └── validate_month_end_date
│   │   ├── standardize_to_calendar_quarters → validate_df_cols
│   │   └── add_quality_flags → validate_df_type, get_income_statement_metrics, get_cash_flow_metrics, get_balance_sheet_metrics
│   ├── calculate_ttm_metrics
│   ├── get_income_statement_metrics
│   └── get_cash_flow_metrics
└── upload_artifact_to_s3 (see above)
```

### scripts/run_phase1_aws.R and scripts/run_phase2_aws.R

AWS wrappers that source the core phase scripts and add notification/logging.

```
scripts/run_phase1_aws.R
├── source("run_phase1_fetch.R")   → (see above)
├── create_pipeline_log
└── send_pipeline_notification

scripts/run_phase2_aws.R
├── source("run_phase2_generate.R") → (see above)
├── create_pipeline_log
├── upload_pipeline_log             → (see above)
├── generate_s3_artifact_key        → (see above)
└── send_pipeline_notification
```

### fetch_options_and_build_artifact()

On-demand entry point for options IV term structure. Runs locally, reads/writes S3.

```
fetch_options_and_build_artifact
├── get_api_key
├── [per ticker]
│   ├── s3_read_ticker_raw_data_single (read existing price data)
│   │   ├── generate_raw_data_s3_key → validate_character_scalar
│   │   └── validate_character_scalar
│   ├── [if no price data in S3 and fetch=TRUE]
│   │   ├── fetch_price → make_av_request → parse_price_response → validate_api_response
│   │   └── s3_write_ticker_raw_data
│   │       ├── generate_raw_data_s3_key (see above)
│   │       └── validate_character_scalar, validate_df_type
│   ├── derive_weekly_dates
│   │   └── validate_df_cols → validate_df_type
│   ├── s3_read_ticker_raw_data_single (read existing options data)
│   ├── [if fetch=TRUE, for missing dates]
│   │   └── fetch_historical_options_for_dates
│   │       ├── fetch_historical_options
│   │       │   ├── validate_character_scalar
│   │       │   ├── make_av_request → build_av_request, get_api_key
│   │       │   └── parse_historical_options_response
│   │       │       ├── validate_api_response
│   │       │       └── empty_options_tibble
│   │       ├── s3_read_ticker_raw_data_single (read existing, append, dedup)
│   │       └── s3_write_ticker_raw_data (write combined)
│   ├── s3_read_ticker_raw_data_single (read complete options data)
│   └── build_options_term_structure
│       ├── validate_character_scalar
│       └── [per observation date]
│           ├── calculate_iv_term_structure
│           │   └── extract_atm_options
│           └── interpolate_iv_to_standard_tenors
├── upload_artifact_to_s3 (raw_term_structure.parquet)
└── upload_artifact_to_s3 (interpolated_term_structure.parquet)
```
