q <- function(ticker, date, close) {
  tibble::tibble(
    ticker = ticker,
    date = as.Date(date),
    open = close, high = close, low = close, close = close,
    adjusted_close = close, volume = 1000,
    dividend_amount = 0, split_coefficient = 1
  )
}

test_that("NULL existing returns the new quotes", {
  new_quotes <- q("AAPL", "2026-05-28", 100)
  expect_equal(accumulate_interim_quotes(NULL, new_quotes), new_quotes)
})

test_that("distinct days from different runs all accumulate", {
  existing <- q("AAPL", "2026-05-27", 100)
  new_quotes <- q("AAPL", "2026-05-28", 101)

  result <- accumulate_interim_quotes(existing, new_quotes)

  expect_equal(nrow(result), 2)
  expect_equal(result$close, c(100, 101))
})

test_that("a same-day re-run replaces that day's bar (newest wins)", {
  existing <- q("AAPL", "2026-05-28", 100)
  new_quotes <- q("AAPL", "2026-05-28", 105)

  result <- accumulate_interim_quotes(existing, new_quotes)

  expect_equal(nrow(result), 1)
  expect_equal(result$close, 105)
})

test_that("newest wins only for the overlapping day, others preserved", {
  existing <- dplyr::bind_rows(
    q("AAPL", "2026-05-27", 100),
    q("AAPL", "2026-05-28", 101)
  )
  new_quotes <- dplyr::bind_rows(
    q("AAPL", "2026-05-28", 999),
    q("AAPL", "2026-05-29", 102)
  )

  result <- accumulate_interim_quotes(existing, new_quotes)

  expect_equal(nrow(result), 3)
  expect_equal(
    result$close[result$date == as.Date("2026-05-28")], 999
  )
  expect_false(any(duplicated(result[c("ticker", "date")])))
})

test_that("multiple tickers accumulate independently", {
  existing <- q("AAPL", "2026-05-28", 100)
  new_quotes <- dplyr::bind_rows(
    q("AAPL", "2026-05-29", 101),
    q("MSFT", "2026-05-29", 400)
  )

  result <- accumulate_interim_quotes(existing, new_quotes)

  expect_equal(nrow(result), 3)
  expect_setequal(unique(result$ticker), c("AAPL", "MSFT"))
})

test_that("result is sorted by ticker then date", {
  existing <- q("MSFT", "2026-05-28", 400)
  new_quotes <- dplyr::bind_rows(
    q("AAPL", "2026-05-29", 101),
    q("AAPL", "2026-05-28", 100)
  )

  result <- accumulate_interim_quotes(existing, new_quotes)

  expect_equal(result$ticker, c("AAPL", "AAPL", "MSFT"))
  expect_equal(
    result$date[result$ticker == "AAPL"],
    as.Date(c("2026-05-28", "2026-05-29"))
  )
})
