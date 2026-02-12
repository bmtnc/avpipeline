#!/usr/bin/env Rscript

# ============================================================================
# Backfill Earnings Estimates to S3
# ============================================================================
# One-time script to fetch EARNINGS_ESTIMATES for all tickers in S3 and write
# the results to s3://{bucket}/raw/{TICKER}/earnings_estimates.parquet.
#
# Run locally:
#   Rscript scripts/backfill_earnings_estimates.R
# ============================================================================

devtools::load_all()

# ---- Configuration ----

s3_bucket <- "avpipeline-artifacts-prod"
aws_region <- "us-east-1"
batch_size <- 25
api_key <- Sys.getenv("ALPHA_VANTAGE_API_KEY")

if (api_key == "") {
  api_key <- get_api_key_from_parameter_store(
    parameter_name = "/avpipeline/alpha-vantage-api-key",
    region = aws_region
  )
}

# ---- Get tickers ----

message("Listing tickers in S3...")
tickers <- s3_list_existing_tickers(s3_bucket, aws_region)
message(sprintf("Found %d tickers", length(tickers)))

# ---- Batch fetch + write ----

n_tickers <- length(tickers)
n_batches <- ceiling(n_tickers / batch_size)
success_count <- 0
error_count <- 0
start_time <- Sys.time()

message(sprintf(
  "Fetching earnings_estimates in %d batches of %d (1 API call per ticker)",
  n_batches,
  batch_size
))

for (batch_idx in seq_len(n_batches)) {
  batch_start <- (batch_idx - 1) * batch_size + 1
  batch_end <- min(batch_idx * batch_size, n_tickers)
  batch_tickers <- tickers[batch_start:batch_end]

  # Build requests
  requests <- lapply(batch_tickers, function(ticker) {
    build_av_request(ticker, "EARNINGS_ESTIMATES", api_key)
  })

  # Fire in parallel (throttled at 1 req/sec)
  responses <- httr2::req_perform_parallel(requests, on_error = "continue")

  # Parse + write to S3
  temp_dir <- tempfile(pattern = "backfill_")
  dir.create(temp_dir, recursive = TRUE)

  write_count <- 0
  for (i in seq_along(responses)) {
    ticker <- batch_tickers[i]
    resp <- responses[[i]]

    tryCatch(
      {
        if (inherits(resp, "error")) {
          stop(conditionMessage(resp))
        }

        parsed <- parse_earnings_estimates_response(resp, ticker)

        if (nrow(parsed) > 0) {
          s3_key <- generate_raw_data_s3_key(ticker, "earnings_estimates")
          local_path <- file.path(temp_dir, s3_key)
          dir.create(
            dirname(local_path),
            recursive = TRUE,
            showWarnings = FALSE
          )
          arrow::write_parquet(parsed, local_path)
          write_count <- write_count + 1
        }

        success_count <- success_count + 1
      },
      error = function(e) {
        error_count <<- error_count + 1
        message(sprintf("  ERROR %s: %s", ticker, conditionMessage(e)))
      }
    )
  }

  # Batch upload to S3
  if (write_count > 0) {
    local_raw_dir <- file.path(temp_dir, "raw")
    s3_target <- paste0("s3://", s3_bucket, "/raw/")
    system2(
      "aws",
      args = c(
        "s3",
        "cp",
        "--recursive",
        local_raw_dir,
        s3_target,
        "--region",
        aws_region,
        "--only-show-errors"
      )
    )
  }

  unlink(temp_dir, recursive = TRUE)

  # Progress
  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "mins"))
  pct <- round(batch_end / n_tickers * 100)
  rate <- batch_end / elapsed
  eta <- (n_tickers - batch_end) / rate

  message(sprintf(
    "Batch %d/%d done | %d/%d tickers (%d%%) | %.1f min elapsed | ~%.0f min remaining | %d errors",
    batch_idx,
    n_batches,
    batch_end,
    n_tickers,
    pct,
    elapsed,
    eta,
    error_count
  ))
}

# ---- Summary ----

total_time <- as.numeric(difftime(Sys.time(), start_time, units = "mins"))
message(sprintf(
  "\nDone in %.1f minutes: %d success, %d errors out of %d tickers",
  total_time,
  success_count,
  error_count,
  n_tickers
))
