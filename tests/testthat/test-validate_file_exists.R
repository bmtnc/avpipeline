test_that("validate_file_exists succeeds with existing file", {
  temp_file <- tempfile()
  writeLines("test", temp_file)
  on.exit(unlink(temp_file))
  expect_null(validate_file_exists(temp_file))
})

test_that("validate_file_exists errors on non-existent file", {
  expect_error(
    validate_file_exists("/nonexistent/path/file.txt"),
    "does not exist"
  )
})

test_that("validate_file_exists validates path is character scalar", {
  expect_error(
    validate_file_exists(123),
    "must be a character scalar"
  )
  expect_error(
    validate_file_exists(c("file1.txt", "file2.txt")),
    "must be a character scalar"
  )
})

test_that("validate_file_exists rejects empty string", {
  expect_error(
    validate_file_exists(""),
    "must be a non-empty string"
  )
})

test_that("validate_file_exists uses custom name in error messages", {
  expect_error(
    validate_file_exists("/nonexistent.txt", name = "cache_path"),
    "cache_path does not exist"
  )
})
