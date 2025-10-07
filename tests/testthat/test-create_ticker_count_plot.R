test_that("create_ticker_count_plot creates ggplot object with valid data", {
  # nolint start
  # fmt: skip
  test_data <- tibble::tibble(
    ticker                  = c("AAPL", "AAPL", "MSFT", "MSFT", "GOOGL"),
    calendar_quarter_ending = as.Date(c("2020-03-31", "2020-06-30", "2020-03-31", "2020-06-30", "2020-03-31")),
    fiscalDateEnding        = as.Date(c("2020-03-31", "2020-06-30", "2020-03-31", "2020-06-30", "2020-03-31"))
  )
  # nolint end
  
  plot <- create_ticker_count_plot(test_data)
  
  expect_s3_class(plot, "ggplot")
  expect_equal(plot$labels$title, "Number of Tickers by Calendar Quarter (Standardized)")
  expect_equal(plot$labels$x, "Calendar Quarter Ending")
  expect_equal(plot$labels$y, "Number of Tickers")
})

test_that("create_ticker_count_plot validates financial_statements is a data.frame", {
  expect_error(
    create_ticker_count_plot("not a data frame"),
    "^create_ticker_count_plot\\(\\): \\[financial_statements\\] must be a data\\.frame, not character$"
  )
  
  expect_error(
    create_ticker_count_plot(list(ticker = "AAPL")),
    "^create_ticker_count_plot\\(\\): \\[financial_statements\\] must be a data\\.frame, not list$"
  )
})

test_that("create_ticker_count_plot validates required columns exist", {
  # Missing ticker column
  # nolint start
  # fmt: skip
  missing_ticker <- tibble::tibble(
    calendar_quarter_ending = as.Date("2020-03-31"),
    fiscalDateEnding        = as.Date("2020-03-31")
  )
  # nolint end
  
  expect_error(
    create_ticker_count_plot(missing_ticker),
    "^create_ticker_count_plot\\(\\): \\[financial_statements\\] missing required columns: ticker$"
  )
  
  # Missing calendar_quarter_ending column
  # nolint start
  # fmt: skip
  missing_calendar <- tibble::tibble(
    ticker           = "AAPL",
    fiscalDateEnding = as.Date("2020-03-31")
  )
  # nolint end
  
  expect_error(
    create_ticker_count_plot(missing_calendar),
    "^create_ticker_count_plot\\(\\): \\[financial_statements\\] missing required columns: calendar_quarter_ending$"
  )
  
  # Missing both columns
  # nolint start
  # fmt: skip
  missing_both <- tibble::tibble(
    fiscalDateEnding = as.Date("2020-03-31")
  )
  # nolint end
  
  expect_error(
    create_ticker_count_plot(missing_both),
    "^create_ticker_count_plot\\(\\): \\[financial_statements\\] missing required columns: ticker, calendar_quarter_ending$"
  )
})

test_that("create_ticker_count_plot handles single ticker", {
  # nolint start
  # fmt: skip
  single_ticker <- tibble::tibble(
    ticker                  = c("AAPL", "AAPL"),
    calendar_quarter_ending = as.Date(c("2020-03-31", "2020-06-30")),
    fiscalDateEnding        = as.Date(c("2020-03-31", "2020-06-30"))
  )
  # nolint end
  
  plot <- create_ticker_count_plot(single_ticker)
  
  expect_s3_class(plot, "ggplot")
})

test_that("create_ticker_count_plot handles multiple quarters", {
  # nolint start
  # fmt: skip
  multi_quarter <- tibble::tibble(
    ticker                  = rep(c("AAPL", "MSFT", "GOOGL"), each = 4),
    calendar_quarter_ending = rep(as.Date(c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31")), 3),
    fiscalDateEnding        = rep(as.Date(c("2020-03-31", "2020-06-30", "2020-09-30", "2020-12-31")), 3)
  )
  # nolint end
  
  plot <- create_ticker_count_plot(multi_quarter)
  
  expect_s3_class(plot, "ggplot")
})
