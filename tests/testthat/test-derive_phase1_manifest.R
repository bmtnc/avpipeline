test_that("derive_phase1_manifest returns empty tibble for empty log", {
  log <- create_pipeline_log()
  result <- derive_phase1_manifest(log)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_equal(names(result), c("ticker", "data_types_updated", "timestamp"))
})

test_that("derive_phase1_manifest filters to success status only", {
  log <- create_pipeline_log()
  log <- add_log_entry(log, "AAPL", "fetch", "price", "success", rows = 100L)
  log <- add_log_entry(log, "BAD", "fetch", "price", "error",
                       error_message = "API error")
  log <- add_log_entry(log, "SKIP", "fetch", "price", "skipped")

  result <- derive_phase1_manifest(log)

  expect_equal(nrow(result), 1)
  expect_equal(result$ticker, "AAPL")
})

test_that("derive_phase1_manifest consolidates data types per ticker", {
  log <- create_pipeline_log()
  log <- add_log_entry(log, "AAPL", "fetch", "price", "success", rows = 100L)
  log <- add_log_entry(log, "AAPL", "fetch", "splits", "success", rows = 5L)
  log <- add_log_entry(log, "AAPL", "fetch", "balance_sheet", "success", rows = 20L)

  result <- derive_phase1_manifest(log)

  expect_equal(nrow(result), 1)
  expect_equal(result$ticker, "AAPL")
  expect_equal(result$data_types_updated, "balance_sheet,price,splits")
})

test_that("derive_phase1_manifest handles multiple tickers", {
  log <- create_pipeline_log()
  log <- add_log_entry(log, "AAPL", "fetch", "price", "success", rows = 100L)
  log <- add_log_entry(log, "MSFT", "fetch", "price", "success", rows = 90L)
  log <- add_log_entry(log, "MSFT", "fetch", "earnings", "success", rows = 10L)
  log <- add_log_entry(log, "BAD", "fetch", "price", "error",
                       error_message = "fail")

  result <- derive_phase1_manifest(log)

  expect_equal(nrow(result), 2)
  expect_true("AAPL" %in% result$ticker)
  expect_true("MSFT" %in% result$ticker)
  expect_false("BAD" %in% result$ticker)

  msft_row <- dplyr::filter(result, ticker == "MSFT")
  expect_equal(msft_row$data_types_updated, "earnings,price")
})

test_that("derive_phase1_manifest uses latest timestamp per ticker", {
  log <- create_pipeline_log()
  log <- add_log_entry(log, "AAPL", "fetch", "price", "success", rows = 100L)
  Sys.sleep(0.01)
  log <- add_log_entry(log, "AAPL", "fetch", "splits", "success", rows = 5L)

  result <- derive_phase1_manifest(log)

  expect_equal(nrow(result), 1)
  expect_true(result$timestamp >= log$timestamp[1])
})

test_that("derive_phase1_manifest rejects non-dataframe input", {
  expect_error(derive_phase1_manifest("not a df"))
  expect_error(derive_phase1_manifest(list()))
})

test_that("derive_phase1_manifest returns empty when all entries are errors", {
  log <- create_pipeline_log()
  log <- add_log_entry(log, "BAD1", "fetch", "price", "error",
                       error_message = "fail")
  log <- add_log_entry(log, "BAD2", "fetch", "price", "error",
                       error_message = "fail")

  result <- derive_phase1_manifest(log)

  expect_equal(nrow(result), 0)
  expect_equal(names(result), c("ticker", "data_types_updated", "timestamp"))
})
