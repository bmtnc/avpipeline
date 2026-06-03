fake_response <- function(json) {
  httr2::response(
    status_code = 200,
    headers = list(`content-type` = "application/json"),
    body = charToRaw(json)
  )
}

ibm_json <- paste0(
  '{"Symbol":"IBM","AssetType":"Common Stock","CIK":"51143",',
  '"Exchange":"NYSE","Currency":"USD","Country":"USA",',
  '"Sector":"TECHNOLOGY","Industry":"INFORMATION TECHNOLOGY SERVICES"}'
)

test_that("parses an overview response to the expected schema and values", {
  result <- parse_overview_response(fake_response(ibm_json), "IBM")

  expect_equal(nrow(result), 1)
  expect_equal(
    names(result),
    c("ticker", "cik", "exchange", "currency", "country", "sector", "industry", "as_of_date")
  )
  expect_equal(result$ticker, "IBM")
  expect_equal(result$cik, "51143")
  expect_equal(result$exchange, "NYSE")
  expect_equal(result$country, "USA")
  expect_equal(result$sector, "TECHNOLOGY")
  expect_equal(result$industry, "INFORMATION TECHNOLOGY SERVICES")
  expect_s3_class(result$as_of_date, "Date")
})

test_that("keeps sector/industry verbatim (UPPERCASE) as Alpha Vantage returns them", {
  result <- parse_overview_response(fake_response(ibm_json), "IBM")
  expect_equal(result$sector, toupper(result$sector))
  expect_equal(result$industry, toupper(result$industry))
})

test_that("returns a zero-row tibble for an invalid symbol (empty object)", {
  result <- parse_overview_response(fake_response("{}"), "BOGUS")
  expect_equal(nrow(result), 0)
  expect_true(all(
    c("ticker", "sector", "industry") %in% names(result)
  ))
})

test_that("missing optional fields become NA, not an error", {
  partial <- '{"Symbol":"XYZ","Sector":"ENERGY"}'
  result <- parse_overview_response(fake_response(partial), "XYZ")
  expect_equal(result$sector, "ENERGY")
  expect_true(is.na(result$industry))
  expect_true(is.na(result$country))
})

test_that("errors on a premium/rate-limit Note response", {
  note <- '{"Note":"rate limit reached"}'
  expect_error(parse_overview_response(fake_response(note), "IBM"), "rate limit")
})

test_that("errors on a standard Error Message response", {
  err <- '{"Error Message":"Invalid API call"}'
  expect_error(parse_overview_response(fake_response(err), "IBM"), "Invalid API call")
})
