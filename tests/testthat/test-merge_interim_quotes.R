price_row <- function(ticker, date, close) {
  tibble::tibble(
    ticker = ticker,
    date = as.Date(date),
    open = close, high = close, low = close, close = close,
    adjusted_close = close, volume = 1000,
    dividend_amount = 0, split_coefficient = 1
  )
}

test_that("interim bars beyond the authoritative frontier are appended", {
  authoritative <- price_row("AAPL", "2026-05-26", 100)
  interim <- price_row("AAPL", "2026-05-27", 101)

  merged <- merge_interim_quotes(authoritative, interim)

  expect_equal(nrow(merged), 2)
  expect_equal(merged$close[merged$date == as.Date("2026-05-27")], 101)
})

test_that("authoritative wins on a shared date (interim dropped)", {
  authoritative <- price_row("AAPL", "2026-05-27", 100)
  interim <- price_row("AAPL", "2026-05-27", 999)

  merged <- merge_interim_quotes(authoritative, interim)

  expect_equal(nrow(merged), 1)
  expect_equal(merged$close, 100)
})

test_that("interim at or below the frontier is ignored", {
  authoritative <- price_row("AAPL", "2026-05-27", 100)
  interim <- price_row("AAPL", "2026-05-20", 50)

  merged <- merge_interim_quotes(authoritative, interim)

  expect_equal(nrow(merged), 1)
  expect_equal(merged$date, as.Date("2026-05-27"))
})

test_that("interim for a ticker absent from authoritative is kept", {
  authoritative <- price_row("AAPL", "2026-05-27", 100)
  interim <- price_row("MSFT", "2026-05-27", 400)

  merged <- merge_interim_quotes(authoritative, interim)

  expect_equal(nrow(merged), 2)
  expect_true("MSFT" %in% merged$ticker)
})

test_that("NULL or empty interim returns authoritative unchanged", {
  authoritative <- price_row("AAPL", "2026-05-27", 100)

  expect_equal(merge_interim_quotes(authoritative, NULL), authoritative)
  expect_equal(
    merge_interim_quotes(authoritative, authoritative[0, ]),
    authoritative
  )
})

test_that("no duplicate (ticker, date) rows are produced", {
  authoritative <- dplyr::bind_rows(
    price_row("AAPL", "2026-05-26", 100),
    price_row("AAPL", "2026-05-27", 101)
  )
  interim <- dplyr::bind_rows(
    price_row("AAPL", "2026-05-27", 999),
    price_row("AAPL", "2026-05-28", 102)
  )

  merged <- merge_interim_quotes(authoritative, interim)

  expect_equal(nrow(merged), 3)
  expect_false(any(duplicated(merged[c("ticker", "date")])))
})
