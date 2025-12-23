#!/usr/bin/env Rscript

# ============================================================================
# Restore Price Data from Version Snapshots
# ============================================================================
# Restores full price history from _versions/ snapshots where the current
# price.parquet was overwritten with compact (100-day) data.
# ============================================================================

devtools::load_all()

aws_region <- Sys.getenv("AWS_REGION", "us-east-1")
s3_bucket <- Sys.getenv("S3_BUCKET", "avpipeline-artifacts-prod")

if (s3_bucket == "") {
  stop("S3_BUCKET environment variable is required")
}

cat("=== RESTORE PRICE DATA FROM SNAPSHOTS ===\n")
cat("Bucket:", s3_bucket, "\n")
cat("Region:", aws_region, "\n\n")

# Get all tickers
all_tickers <- s3_list_existing_tickers(s3_bucket, aws_region)
cat("Total tickers:", length(all_tickers), "\n\n")

restored_count <- 0
skipped_count <- 0
error_count <- 0

for (ticker in all_tickers) {
  tryCatch({
    # Check current price file
    current_key <- paste0("raw/", ticker, "/price.parquet")
    current_path <- tempfile(fileext = ".parquet")

    # Try to download current price file
    current_exists <- tryCatch({
      aws.s3::save_object(
        object = current_key,
        bucket = s3_bucket,
        file = current_path,
        region = aws_region
      )
      TRUE
    }, error = function(e) FALSE)

    if (!current_exists) {
      skipped_count <- skipped_count + 1
      next
    }

    current_data <- arrow::read_parquet(current_path)
    current_rows <- nrow(current_data)

    # List version snapshots
    versions_prefix <- paste0("raw/", ticker, "/_versions/")
    versions <- aws.s3::get_bucket(
      bucket = s3_bucket,
      prefix = versions_prefix,
      region = aws_region
    )

    # Filter to price snapshots
    price_versions <- Filter(
      function(x) grepl("^price_.*\\.parquet$", basename(x$Key)),
      versions
    )

    if (length(price_versions) == 0) {
      skipped_count <- skipped_count + 1
      unlink(current_path)
      next
    }

    # Find the largest snapshot
    best_version <- NULL
    best_rows <- current_rows

    for (v in price_versions) {
      version_path <- tempfile(fileext = ".parquet")
      tryCatch({
        aws.s3::save_object(
          object = v$Key,
          bucket = s3_bucket,
          file = version_path,
          region = aws_region
        )
        version_data <- arrow::read_parquet(version_path)
        if (nrow(version_data) > best_rows) {
          best_rows <- nrow(version_data)
          best_version <- v$Key
        }
        unlink(version_path)
      }, error = function(e) {
        unlink(version_path)
      })
    }

    if (!is.null(best_version) && best_rows > current_rows) {
      # Restore from snapshot
      version_path <- tempfile(fileext = ".parquet")
      aws.s3::save_object(
        object = best_version,
        bucket = s3_bucket,
        file = version_path,
        region = aws_region
      )

      # Upload as current price file
      aws.s3::put_object(
        file = version_path,
        object = current_key,
        bucket = s3_bucket,
        region = aws_region
      )

      cat(sprintf("[RESTORED] %s: %d -> %d rows (from %s)\n",
                  ticker, current_rows, best_rows, basename(best_version)))
      restored_count <- restored_count + 1
      unlink(version_path)
    } else {
      skipped_count <- skipped_count + 1
    }

    unlink(current_path)

  }, error = function(e) {
    cat(sprintf("[ERROR] %s: %s\n", ticker, conditionMessage(e)))
    error_count <- error_count + 1
  })
}

cat("\n=== SUMMARY ===\n")
cat("Restored:", restored_count, "\n")
cat("Skipped:", skipped_count, "\n")
cat("Errors:", error_count, "\n")
