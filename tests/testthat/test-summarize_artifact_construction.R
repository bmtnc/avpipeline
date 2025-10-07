test_that("summarize_artifact_construction prints summary with valid data", {
  # nolint start
  # fmt: skip
  original_data <- tibble::tibble(
    ticker           = c("AAPL", "AAPL", "AAPL", "MSFT", "MSFT", "MSFT"),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30", "2020-03-31", "2020-06-30", "2020-09-30"))
  )
  
  final_data <- tibble::tibble(
    ticker                   = c("AAPL", "AAPL", "MSFT", "MSFT"),
    fiscalDateEnding         = as.Date(c("2020-03-31", "2020-06-30", "2020-03-31", "2020-06-30")),
    has_complete_financials  = c(TRUE, TRUE, TRUE, TRUE),
    has_earnings_metadata    = c(TRUE, FALSE, TRUE, TRUE)
  )
  # nolint end
  
  expect_message(
    summarize_artifact_construction(original_data, final_data),
    "Removed 2 observations to ensure continuous quarterly spacing"
  )
})

test_that("summarize_artifact_construction validates original_data is a data.frame", {
  # nolint start
  # fmt: skip
  final_data <- tibble::tibble(
    ticker           = "AAPL",
    fiscalDateEnding = as.Date("2020-03-31")
  )
  # nolint end
  
  expect_error(
    summarize_artifact_construction("not a data frame", final_data),
    "^summarize_artifact_construction\\(\\): \\[original_data\\] must be a data\\.frame, not character$"
  )
  
  expect_error(
    summarize_artifact_construction(list(ticker = "AAPL"), final_data),
    "^summarize_artifact_construction\\(\\): \\[original_data\\] must be a data\\.frame, not list$"
  )
})

test_that("summarize_artifact_construction validates final_data is a data.frame", {
  # nolint start
  # fmt: skip
  original_data <- tibble::tibble(
    ticker           = "AAPL",
    fiscalDateEnding = as.Date("2020-03-31")
  )
  # nolint end
  
  expect_error(
    summarize_artifact_construction(original_data, "not a data frame"),
    "^summarize_artifact_construction\\(\\): \\[final_data\\] must be a data\\.frame, not character$"
  )
  
  expect_error(
    summarize_artifact_construction(original_data, list(ticker = "AAPL")),
    "^summarize_artifact_construction\\(\\): \\[final_data\\] must be a data\\.frame, not list$"
  )
})

test_that("summarize_artifact_construction validates removed_detail is data.frame or NULL", {
  # nolint start
  # fmt: skip
  original_data <- tibble::tibble(
    ticker           = "AAPL",
    fiscalDateEnding = as.Date("2020-03-31")
  )
  
  final_data <- tibble::tibble(
    ticker           = "AAPL",
    fiscalDateEnding = as.Date("2020-03-31")
  )
  # nolint end
  
  expect_error(
    summarize_artifact_construction(original_data, final_data, removed_detail = "not a data frame"),
    "^summarize_artifact_construction\\(\\): \\[removed_detail\\] must be a data\\.frame or NULL, not character$"
  )
})

test_that("summarize_artifact_construction handles NULL removed_detail", {
  # nolint start
  # fmt: skip
  original_data <- tibble::tibble(
    ticker           = c("AAPL", "AAPL"),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30"))
  )
  
  final_data <- tibble::tibble(
    ticker           = "AAPL",
    fiscalDateEnding = as.Date("2020-03-31")
  )
  # nolint end
  
  expect_message(
    summarize_artifact_construction(original_data, final_data, removed_detail = NULL),
    "Removed 1 observations to ensure continuous quarterly spacing"
  )
})

test_that("summarize_artifact_construction handles removed_detail with data", {
  # nolint start
  # fmt: skip
  original_data <- tibble::tibble(
    ticker           = c("AAPL", "AAPL", "AAPL"),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30"))
  )
  
  final_data <- tibble::tibble(
    ticker           = "AAPL",
    fiscalDateEnding = as.Date("2020-03-31")
  )
  
  removed_detail <- tibble::tibble(
    ticker           = "AAPL",
    removed_count    = 2,
    earliest_removed = as.Date("2020-06-30"),
    latest_removed   = as.Date("2020-09-30")
  )
  # nolint end
  
  expect_message(
    summarize_artifact_construction(original_data, final_data, removed_detail),
    "AAPL: 2 observations removed"
  )
})

test_that("summarize_artifact_construction handles completely removed tickers", {
  # nolint start
  # fmt: skip
  original_data <- tibble::tibble(
    ticker           = c("AAPL", "MSFT", "GOOGL"),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-03-31", "2020-03-31"))
  )
  
  final_data <- tibble::tibble(
    ticker           = "AAPL",
    fiscalDateEnding = as.Date("2020-03-31")
  )
  # nolint end
  
  expect_message(
    summarize_artifact_construction(original_data, final_data),
    "Removed 2 tickers with no continuous quarterly series"
  )
  
  expect_message(
    summarize_artifact_construction(original_data, final_data),
    "MSFT, GOOGL"
  )
})

test_that("summarize_artifact_construction calculates gap statistics", {
  # nolint start
  # fmt: skip
  original_data <- tibble::tibble(
    ticker           = c("AAPL", "AAPL", "AAPL"),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30"))
  )
  
  final_data <- tibble::tibble(
    ticker           = c("AAPL", "AAPL", "AAPL"),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30", "2020-09-30"))
  )
  # nolint end
  
  expect_message(
    summarize_artifact_construction(original_data, final_data),
    "Gap statistics \\(for informational purposes\\):"
  )
})

test_that("summarize_artifact_construction handles data without quality flags", {
  # nolint start
  # fmt: skip
  original_data <- tibble::tibble(
    ticker           = c("AAPL", "AAPL"),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30"))
  )
  
  final_data <- tibble::tibble(
    ticker           = c("AAPL", "AAPL"),
    fiscalDateEnding = as.Date(c("2020-03-31", "2020-06-30"))
  )
  # nolint end
  
  expect_message(
    summarize_artifact_construction(original_data, final_data),
    "Final financial statements artifact:"
  )
})

test_that("summarize_artifact_construction returns invisible NULL", {
  # nolint start
  # fmt: skip
  original_data <- tibble::tibble(
    ticker           = "AAPL",
    fiscalDateEnding = as.Date("2020-03-31")
  )
  
  final_data <- tibble::tibble(
    ticker           = "AAPL",
    fiscalDateEnding = as.Date("2020-03-31")
  )
  # nolint end
  
  result <- summarize_artifact_construction(original_data, final_data)
  
  expect_null(result)
})
