test_that("NULL manifest triggers full reprocess", {
  result <- determine_phase2_reprocess_set(
    manifest = NULL,
    previous_artifact_tickers = c("AAPL", "MSFT"),
    s3_tickers = c("AAPL", "MSFT", "GOOG")
  )

  expect_equal(result$reprocess_tickers, c("AAPL", "GOOG", "MSFT"))
  expect_equal(result$unchanged_tickers, character(0))
  expect_equal(result$dropped_tickers, character(0))
  expect_equal(result$reason, "no_manifest")
})

test_that("empty manifest triggers full reprocess", {
  empty_manifest <- tibble::tibble(
    ticker = character(),
    data_types_updated = character(),
    timestamp = as.POSIXct(character())
  )

  result <- determine_phase2_reprocess_set(
    manifest = empty_manifest,
    previous_artifact_tickers = c("AAPL", "MSFT"),
    s3_tickers = c("AAPL", "MSFT")
  )

  expect_equal(result$reason, "no_manifest")
  expect_equal(result$reprocess_tickers, c("AAPL", "MSFT"))
})

test_that("no previous artifact triggers full reprocess", {
  manifest <- tibble::tibble(
    ticker = "AAPL",
    data_types_updated = "price",
    timestamp = Sys.time()
  )

  result <- determine_phase2_reprocess_set(
    manifest = manifest,
    previous_artifact_tickers = character(0),
    s3_tickers = c("AAPL", "MSFT")
  )

  expect_equal(result$reason, "no_previous_artifact")
  expect_equal(result$reprocess_tickers, c("AAPL", "MSFT"))
})

test_that("standard incremental case works correctly", {
  manifest <- tibble::tibble(
    ticker = c("MSFT", "GOOG"),
    data_types_updated = c("price,quarterly", "price"),
    timestamp = rep(Sys.time(), 2)
  )

  result <- determine_phase2_reprocess_set(
    manifest = manifest,
    previous_artifact_tickers = c("AAPL", "MSFT", "GOOG", "AMZN"),
    s3_tickers = c("AAPL", "MSFT", "GOOG", "AMZN", "NVDA")
  )

  expect_equal(result$reason, "incremental")
  # MSFT + GOOG (manifest) + NVDA (new) = reprocess
  expect_equal(result$reprocess_tickers, c("GOOG", "MSFT", "NVDA"))
  # AAPL + AMZN = unchanged
  expect_equal(result$unchanged_tickers, c("AAPL", "AMZN"))
  expect_equal(result$dropped_tickers, character(0))
})

test_that("dropped tickers detected correctly", {
  manifest <- tibble::tibble(
    ticker = "AAPL",
    data_types_updated = "price",
    timestamp = Sys.time()
  )

  result <- determine_phase2_reprocess_set(
    manifest = manifest,
    previous_artifact_tickers = c("AAPL", "MSFT", "DELISTED"),
    s3_tickers = c("AAPL", "MSFT")
  )

  expect_equal(result$reason, "incremental")
  expect_equal(result$reprocess_tickers, "AAPL")
  expect_equal(result$unchanged_tickers, "MSFT")
  expect_equal(result$dropped_tickers, "DELISTED")
})

test_that("manifest ticker not in S3 is excluded from reprocess", {
  manifest <- tibble::tibble(
    ticker = c("AAPL", "GONE"),
    data_types_updated = c("price", "price"),
    timestamp = rep(Sys.time(), 2)
  )

  result <- determine_phase2_reprocess_set(
    manifest = manifest,
    previous_artifact_tickers = c("AAPL", "MSFT"),
    s3_tickers = c("AAPL", "MSFT")
  )

  expect_equal(result$reprocess_tickers, "AAPL")
  expect_equal(result$unchanged_tickers, "MSFT")
})

test_that("new tickers and manifest tickers both included in reprocess", {
  manifest <- tibble::tibble(
    ticker = "MSFT",
    data_types_updated = "quarterly",
    timestamp = Sys.time()
  )

  result <- determine_phase2_reprocess_set(
    manifest = manifest,
    previous_artifact_tickers = c("AAPL", "MSFT"),
    s3_tickers = c("AAPL", "MSFT", "NVDA")
  )

  expect_equal(result$reprocess_tickers, c("MSFT", "NVDA"))
  expect_equal(result$unchanged_tickers, "AAPL")
})

test_that("all tickers on manifest results in empty unchanged", {
  manifest <- tibble::tibble(
    ticker = c("AAPL", "MSFT"),
    data_types_updated = c("price", "price"),
    timestamp = rep(Sys.time(), 2)
  )

  result <- determine_phase2_reprocess_set(
    manifest = manifest,
    previous_artifact_tickers = c("AAPL", "MSFT"),
    s3_tickers = c("AAPL", "MSFT")
  )

  expect_equal(result$reprocess_tickers, c("AAPL", "MSFT"))
  expect_equal(result$unchanged_tickers, character(0))
})

test_that("no manifest tickers and no new tickers results in all unchanged", {
  manifest <- tibble::tibble(
    ticker = "OTHER",
    data_types_updated = "price",
    timestamp = Sys.time()
  )

  result <- determine_phase2_reprocess_set(
    manifest = manifest,
    previous_artifact_tickers = c("AAPL", "MSFT"),
    s3_tickers = c("AAPL", "MSFT")
  )

  # OTHER not in s3_tickers, so excluded
  expect_equal(result$reprocess_tickers, character(0))
  expect_equal(result$unchanged_tickers, c("AAPL", "MSFT"))
})

test_that("results are sorted alphabetically", {
  manifest <- tibble::tibble(
    ticker = c("MSFT", "AAPL"),
    data_types_updated = c("price", "price"),
    timestamp = rep(Sys.time(), 2)
  )

  result <- determine_phase2_reprocess_set(
    manifest = manifest,
    previous_artifact_tickers = c("MSFT", "AAPL", "GOOG"),
    s3_tickers = c("MSFT", "AAPL", "GOOG")
  )

  expect_equal(result$reprocess_tickers, c("AAPL", "MSFT"))
  expect_equal(result$unchanged_tickers, "GOOG")
})
