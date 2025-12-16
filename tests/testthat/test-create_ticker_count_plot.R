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
