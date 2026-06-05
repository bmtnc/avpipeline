bulk_fixture <- function() {
  # nolint start
  # fmt: skip
  tibble::tribble(
    ~ticker, ~date,        ~timestamp,            ~open,   ~high,   ~low,    ~close,  ~volume,   ~previous_close,
    "MSFT",  "2026-05-28", "2026-05-28 19:59:59", 412.67,  429.49,  412.67,  426.99,  47250541,  412.67,
    "IBM",   "2026-05-28", "2026-05-28 19:59:58", 261.45,  268.89,  257.09,  264.20,  12432879,  255.20
  ) %>%
    dplyr::mutate(date = as.Date(date))
  # nolint end
}

test_that("output has exactly the price artifact columns", {
  result <- normalize_bulk_quotes_to_price_schema(bulk_fixture())

  expect_equal(
    names(result),
    c(
      "ticker",
      "date",
      "open",
      "high",
      "low",
      "close",
      "adjusted_close",
      "volume",
      "dividend_amount",
      "split_coefficient"
    )
  )
})

test_that("adjusted_close is synthesized to equal close", {
  result <- normalize_bulk_quotes_to_price_schema(bulk_fixture())
  expect_equal(result$adjusted_close, result$close)
})

test_that("corporate-action fields are neutral", {
  result <- normalize_bulk_quotes_to_price_schema(bulk_fixture())
  expect_true(all(result$dividend_amount == 0))
  expect_true(all(result$split_coefficient == 1))
})

test_that("raw OHLCV passes through unchanged", {
  result <- normalize_bulk_quotes_to_price_schema(bulk_fixture())
  msft <- result[result$ticker == "MSFT", ]

  expect_equal(msft$open, 412.67)
  expect_equal(msft$close, 426.99)
  expect_equal(msft$volume, 47250541)
})
