test_that("s3_read_phase1_manifest rejects invalid bucket_name", {
  expect_error(s3_read_phase1_manifest(123))
  expect_error(s3_read_phase1_manifest(c("a", "b")))
})

test_that("s3_read_phase1_manifest rejects invalid region", {
  expect_error(s3_read_phase1_manifest("bucket", region = 123))
})
