test_that("validate_artifact_files succeeds with existing files", {
  temp_dir <- tempdir()
  test_files <- file.path(temp_dir, c("file1.csv", "file2.csv"))

  file.create(test_files)

  expect_silent(validate_artifact_files(test_files))

  unlink(test_files)
})

test_that("validate_artifact_files stops on missing files", {
  missing_files <- c("nonexistent1.csv", "nonexistent2.csv")

  expect_error(
    validate_artifact_files(missing_files),
    "^validate_artifact_files\\(\\): Missing required files: nonexistent1\\.csv, nonexistent2\\.csv$"
  )
})

test_that("validate_artifact_files validates input type", {
  expect_error(
    validate_artifact_files(123),
    "^validate_artifact_files\\(\\): \\[file_paths\\] must be a character vector, not numeric$"
  )

  expect_error(
    validate_artifact_files(list("file.csv")),
    "^validate_artifact_files\\(\\): \\[file_paths\\] must be a character vector, not list$"
  )
})

test_that("validate_artifact_files handles mixed existing and missing files", {
  temp_dir <- tempdir()
  existing_file <- file.path(temp_dir, "exists.csv")
  missing_file <- "missing.csv"

  file.create(existing_file)

  expect_error(
    validate_artifact_files(c(existing_file, missing_file)),
    "Missing required files: missing\\.csv$"
  )

  unlink(existing_file)
})
