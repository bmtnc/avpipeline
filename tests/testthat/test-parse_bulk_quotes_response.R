fake_response <- function(json) {
  httr2::response(
    status_code = 200,
    headers = list(`content-type` = "application/json"),
    body = charToRaw(json)
  )
}

success_json <- paste0(
  '{"endpoint":"Realtime Bulk Quotes","message":"success","data":[',
  '{"symbol":"MSFT","timestamp":"2026-05-28 19:59:59.667","open":"412.67",',
  '"high":"429.49","low":"412.67","close":"426.99","volume":"47250541",',
  '"previous_close":"412.67","change":"14.32","change_percent":"3.47"},',
  '{"symbol":"IBM","timestamp":"2026-05-28 19:59:58.641","open":"261.45",',
  '"high":"268.89","low":"257.09","close":"264.2","volume":"12432879",',
  '"previous_close":"255.2","change":"9.0","change_percent":"3.52"}]}'
)

test_that("parses a success response to the expected schema and types", {
  result <- parse_bulk_quotes_response(fake_response(success_json))

  expect_equal(nrow(result), 2)
  expect_equal(
    names(result),
    c(
      "ticker",
      "date",
      "timestamp",
      "open",
      "high",
      "low",
      "close",
      "volume",
      "previous_close"
    )
  )
  expect_type(result$close, "double")
  expect_s3_class(result$date, "Date")
})

test_that("extracts values correctly", {
  result <- parse_bulk_quotes_response(fake_response(success_json))
  msft <- result[result$ticker == "MSFT", ]

  expect_equal(msft$date, as.Date("2026-05-28"))
  expect_equal(msft$close, 426.99)
  expect_equal(msft$previous_close, 412.67)
  expect_equal(msft$volume, 47250541)
})

test_that("errors on a premium/rate-limit Information response", {
  info <- '{"Information":"premium endpoint"}'
  expect_error(
    parse_bulk_quotes_response(fake_response(info)),
    "Information|premium"
  )
})

test_that("errors on a standard Error Message response", {
  err <- '{"Error Message":"Invalid API call"}'
  expect_error(
    parse_bulk_quotes_response(fake_response(err)),
    "Invalid API call"
  )
})

test_that("errors when the data array is missing or empty", {
  expect_error(
    parse_bulk_quotes_response(fake_response('{"message":"success"}')),
    "data"
  )
  expect_error(
    parse_bulk_quotes_response(fake_response(
      '{"message":"success","data":[]}'
    )),
    "data"
  )
})
