test_that("clean_single_statement_anomalies validates data parameter", {
  expect_error(
    clean_single_statement_anomalies("not a df", c("metric1"), "test"),
    "^Input data must be a data.frame. Received: character$"
  )
})

test_that("clean_single_statement_anomalies validates metrics parameter", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker           = c("A", "A"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2021-12-31")),
    metric1          = c(100, 150)
  )
  # nolint end

  expect_error(
    clean_single_statement_anomalies(test_data, 123, "test"),
    "^clean_single_statement_anomalies\\(\\): \\[metrics\\] must be a character vector, not numeric$"
  )
})

test_that("clean_single_statement_anomalies validates statement_name parameter", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker           = c("A", "A"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2021-12-31")),
    metric1          = c(100, 150)
  )
  # nolint end

  expect_error(
    clean_single_statement_anomalies(test_data, c("metric1"), c("test1", "test2")),
    "^clean_single_statement_anomalies\\(\\): \\[statement_name\\] must be a character scalar, not character of length 2$"
  )
})

test_that("clean_single_statement_anomalies validates threshold parameter", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker           = c("A", "A"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2021-12-31")),
    metric1          = c(100, 150)
  )
  # nolint end

  expect_error(
    clean_single_statement_anomalies(test_data, c("metric1"), "test", threshold = -1),
    "^clean_single_statement_anomalies\\(\\): \\[threshold\\] must be a positive numeric scalar"
  )
})

test_that("clean_single_statement_anomalies validates min_obs parameter", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker           = c("A", "A"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2021-12-31")),
    metric1          = c(100, 150)
  )
  # nolint end

  expect_error(
    clean_single_statement_anomalies(test_data, c("metric1"), "test", min_obs = 0),
    "^clean_single_statement_anomalies\\(\\): \\[min_obs\\] must be a positive numeric scalar"
  )
})

test_that("clean_single_statement_anomalies handles insufficient observations", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker           = c("A", "A"),
    fiscalDateEnding = as.Date(c("2020-12-31", "2021-12-31")),
    metric1          = c(100, 150)
  )
  # nolint end

  result <- clean_single_statement_anomalies(
    test_data,
    c("metric1"),
    "test statement",
    min_obs = 100
  )

  expect_equal(nrow(result), nrow(test_data))
})
