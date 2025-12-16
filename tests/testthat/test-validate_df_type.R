test_that("validate_df_type succeeds with data.frame", {
  df <- data.frame(a = 1, b = 2)
  expect_null(validate_df_type(df))
})

test_that("validate_df_type succeeds with tibble", {
  df <- tibble::tibble(a = 1, b = 2)
  expect_null(validate_df_type(df))
})

test_that("validate_df_type succeeds with empty data.frame", {
  df <- data.frame()
  expect_null(validate_df_type(df))
})

test_that("validate_df_type errors on non-data.frame", {
  expect_error(
    validate_df_type("not a df"),
    "^Input data must be a data.frame. Received: character$"
  )

  expect_error(
    validate_df_type(list(a = 1, b = 2)),
    "^Input data must be a data.frame. Received: list$"
  )

  expect_error(
    validate_df_type(c(1, 2, 3)),
    "^Input data must be a data.frame. Received: numeric$"
  )
})
