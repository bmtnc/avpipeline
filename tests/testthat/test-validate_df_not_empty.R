test_that("validate_df_not_empty succeeds with non-empty data.frame", {
  df <- data.frame(a = 1, b = 2)
  expect_null(validate_df_not_empty(df))
})

test_that("validate_df_not_empty succeeds with single row data.frame", {
  df <- data.frame(a = 1)
  expect_null(validate_df_not_empty(df))
})

test_that("validate_df_not_empty succeeds with large data.frame", {
  df <- data.frame(a = 1:1000, b = 1:1000)
  expect_null(validate_df_not_empty(df))
})

test_that("validate_df_not_empty errors on empty data.frame", {
  empty_df <- data.frame()
  expect_error(
    validate_df_not_empty(empty_df),
    "^Input data is empty \\(0 rows\\)$"
  )
})

test_that("validate_df_not_empty errors on empty tibble", {
  empty_tibble <- tibble::tibble()
  expect_error(
    validate_df_not_empty(empty_tibble),
    "^Input data is empty \\(0 rows\\)$"
  )
})
