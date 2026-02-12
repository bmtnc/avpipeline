test_that("s3_write_phase1_manifest rejects non-dataframe pipeline_log", {
  expect_error(s3_write_phase1_manifest("not a df", "bucket"))
  expect_error(s3_write_phase1_manifest(list(), "bucket"))
})

test_that("s3_write_phase1_manifest rejects invalid bucket_name", {
  log <- create_pipeline_log()
  expect_error(s3_write_phase1_manifest(log, 123))
  expect_error(s3_write_phase1_manifest(log, c("a", "b")))
})

test_that("s3_write_phase1_manifest rejects invalid region", {
  log <- create_pipeline_log()
  expect_error(s3_write_phase1_manifest(log, "bucket", region = 123))
})
