test_that("parse_earnings_estimates_response parses JSON correctly", {
  sample_json <- jsonlite::toJSON(list(
    symbol = "IBM",
    estimates = data.frame(
      date = c("2026-06-30", "2026-03-31", "2025-12-31"),
      horizon = c("next fiscal quarter", "historical fiscal quarter", "historical fiscal year"),
      eps_estimate_average = c("3.0256", "1.8093", "11.3508"),
      eps_estimate_high = c("3.2100", "1.8500", "11.5000"),
      eps_estimate_low = c("2.8000", "1.7600", "11.0600"),
      eps_estimate_analyst_count = c("15.0000", "15.0000", "20.0000"),
      eps_estimate_average_7_days_ago = c("3.0170", "1.9208", "11.3538"),
      eps_estimate_average_30_days_ago = c("3.0084", "1.9344", "11.3643"),
      eps_estimate_average_60_days_ago = c("3.0005", "1.9280", "11.3531"),
      eps_estimate_average_90_days_ago = c("2.9867", "1.9339", "11.3564"),
      eps_estimate_revision_up_trailing_7_days = c("0.0000", "0.0000", "1.0000"),
      eps_estimate_revision_down_trailing_7_days = c(NA, NA, NA),
      eps_estimate_revision_up_trailing_30_days = c("7.0000", "4.0000", "1.0000"),
      eps_estimate_revision_down_trailing_30_days = c("5.0000", "8.0000", "6.0000"),
      revenue_estimate_average = c("17698008260.00", "15628294330.00", "67042150760.00"),
      revenue_estimate_high = c("17943000000.00", "16010000000.00", "67432000000.00"),
      revenue_estimate_low = c("17451000000.00", "15161000000.00", "66798000000.00"),
      revenue_estimate_analyst_count = c("14.00", "15.00", "20.00"),
      stringsAsFactors = FALSE
    )
  ), auto_unbox = TRUE)

  mock_response <- structure(
    list(body = charToRaw(as.character(sample_json))),
    class = "httr2_response"
  )
  local_mocked_bindings(
    resp_body_string = function(response) as.character(sample_json),
    .package = "httr2"
  )

  result <- parse_earnings_estimates_response(mock_response, "IBM")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_equal(result$ticker, rep("IBM", 3))
  expect_s3_class(result$fiscalDateEnding, "Date")
  expect_equal(result$fiscalDateEnding, as.Date(c("2026-06-30", "2026-03-31", "2025-12-31")))
  expect_equal(result$horizon, c("next fiscal quarter", "historical fiscal quarter", "historical fiscal year"))
  expect_type(result$eps_estimate_average, "double")
  expect_equal(result$eps_estimate_average, c(3.0256, 1.8093, 11.3508))
  expect_type(result$revenue_estimate_average, "double")
  expect_equal(result$revenue_estimate_average, c(17698008260, 15628294330, 67042150760))
  expect_type(result$eps_estimate_analyst_count, "double")
  expect_equal(result$eps_estimate_analyst_count, c(15, 15, 20))
})

test_that("parse_earnings_estimates_response handles null values as NA", {
  sample_json <- jsonlite::toJSON(list(
    symbol = "TEST",
    estimates = data.frame(
      date = "2025-09-30",
      horizon = "historical fiscal quarter",
      eps_estimate_average = "2.0",
      eps_estimate_high = "2.5",
      eps_estimate_low = "1.5",
      eps_estimate_analyst_count = "10.0",
      eps_estimate_average_7_days_ago = "None",
      eps_estimate_average_30_days_ago = "None",
      eps_estimate_average_60_days_ago = "None",
      eps_estimate_average_90_days_ago = "None",
      eps_estimate_revision_up_trailing_7_days = "None",
      eps_estimate_revision_down_trailing_7_days = "None",
      eps_estimate_revision_up_trailing_30_days = "None",
      eps_estimate_revision_down_trailing_30_days = "None",
      revenue_estimate_average = "1000000.00",
      revenue_estimate_high = "1100000.00",
      revenue_estimate_low = "900000.00",
      revenue_estimate_analyst_count = "5.00",
      stringsAsFactors = FALSE
    )
  ), auto_unbox = TRUE)

  mock_response <- structure(
    list(body = charToRaw(as.character(sample_json))),
    class = "httr2_response"
  )
  local_mocked_bindings(
    resp_body_string = function(response) as.character(sample_json),
    .package = "httr2"
  )

  result <- parse_earnings_estimates_response(mock_response, "TEST")

  expect_equal(nrow(result), 1)
  expect_true(is.na(result$eps_estimate_average_7_days_ago))
  expect_true(is.na(result$eps_estimate_revision_down_trailing_7_days))
  expect_equal(result$eps_estimate_average, 2.0)
})

test_that("parse_earnings_estimates_response returns empty tibble for empty data", {
  empty_json <- jsonlite::toJSON(list(
    symbol = "EMPTY",
    estimates = list()
  ), auto_unbox = TRUE)

  mock_response <- structure(
    list(body = charToRaw(as.character(empty_json))),
    class = "httr2_response"
  )
  local_mocked_bindings(
    resp_body_string = function(response) as.character(empty_json),
    .package = "httr2"
  )

  expect_warning(
    result <- parse_earnings_estimates_response(mock_response, "EMPTY"),
    "No earnings estimates data found"
  )
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("parse_earnings_estimates_response propagates API errors", {
  error_json <- jsonlite::toJSON(list(
    `Error Message` = "Invalid API call"
  ), auto_unbox = TRUE)

  mock_response <- structure(
    list(body = charToRaw(as.character(error_json))),
    class = "httr2_response"
  )
  local_mocked_bindings(
    resp_body_string = function(response) as.character(error_json),
    .package = "httr2"
  )

  expect_error(
    parse_earnings_estimates_response(mock_response, "IBM"),
    "Alpha Vantage API error"
  )
})

test_that("parse_earnings_estimates_response errors when estimates key missing", {
  bad_json <- jsonlite::toJSON(list(
    symbol = "IBM",
    other_data = list()
  ), auto_unbox = TRUE)

  mock_response <- structure(
    list(body = charToRaw(as.character(bad_json))),
    class = "httr2_response"
  )
  local_mocked_bindings(
    resp_body_string = function(response) as.character(bad_json),
    .package = "httr2"
  )

  expect_error(
    parse_earnings_estimates_response(mock_response, "IBM"),
    "No estimates found"
  )
})

test_that("parse_earnings_estimates_response has correct columns", {
  sample_json <- jsonlite::toJSON(list(
    symbol = "TEST",
    estimates = data.frame(
      date = "2025-06-30",
      horizon = "historical fiscal quarter",
      eps_estimate_average = "2.0",
      eps_estimate_high = "2.5",
      eps_estimate_low = "1.5",
      eps_estimate_analyst_count = "10.0",
      eps_estimate_average_7_days_ago = "2.0",
      eps_estimate_average_30_days_ago = "2.0",
      eps_estimate_average_60_days_ago = "2.0",
      eps_estimate_average_90_days_ago = "2.0",
      eps_estimate_revision_up_trailing_7_days = "1.0",
      eps_estimate_revision_down_trailing_7_days = "0.0",
      eps_estimate_revision_up_trailing_30_days = "2.0",
      eps_estimate_revision_down_trailing_30_days = "1.0",
      revenue_estimate_average = "1000.0",
      revenue_estimate_high = "1100.0",
      revenue_estimate_low = "900.0",
      revenue_estimate_analyst_count = "8.0",
      stringsAsFactors = FALSE
    )
  ), auto_unbox = TRUE)

  mock_response <- structure(
    list(body = charToRaw(as.character(sample_json))),
    class = "httr2_response"
  )
  local_mocked_bindings(
    resp_body_string = function(response) as.character(sample_json),
    .package = "httr2"
  )

  result <- parse_earnings_estimates_response(mock_response, "TEST")

  expected_cols <- c("ticker", "fiscalDateEnding", "horizon", get_earnings_estimates_metrics())
  expect_equal(names(result), expected_cols)
})

test_that("parse_earnings_estimates_response sorts by date descending", {
  sample_json <- jsonlite::toJSON(list(
    symbol = "TEST",
    estimates = data.frame(
      date = c("2025-03-31", "2025-09-30", "2025-06-30"),
      horizon = rep("historical fiscal quarter", 3),
      eps_estimate_average = c("1.0", "3.0", "2.0"),
      eps_estimate_high = c("1.0", "3.0", "2.0"),
      eps_estimate_low = c("1.0", "3.0", "2.0"),
      eps_estimate_analyst_count = c("10.0", "10.0", "10.0"),
      eps_estimate_average_7_days_ago = c("1.0", "3.0", "2.0"),
      eps_estimate_average_30_days_ago = c("1.0", "3.0", "2.0"),
      eps_estimate_average_60_days_ago = c("1.0", "3.0", "2.0"),
      eps_estimate_average_90_days_ago = c("1.0", "3.0", "2.0"),
      eps_estimate_revision_up_trailing_7_days = c("0.0", "0.0", "0.0"),
      eps_estimate_revision_down_trailing_7_days = c("0.0", "0.0", "0.0"),
      eps_estimate_revision_up_trailing_30_days = c("0.0", "0.0", "0.0"),
      eps_estimate_revision_down_trailing_30_days = c("0.0", "0.0", "0.0"),
      revenue_estimate_average = c("100.0", "300.0", "200.0"),
      revenue_estimate_high = c("100.0", "300.0", "200.0"),
      revenue_estimate_low = c("100.0", "300.0", "200.0"),
      revenue_estimate_analyst_count = c("5.0", "5.0", "5.0"),
      stringsAsFactors = FALSE
    )
  ), auto_unbox = TRUE)

  mock_response <- structure(
    list(body = charToRaw(as.character(sample_json))),
    class = "httr2_response"
  )
  local_mocked_bindings(
    resp_body_string = function(response) as.character(sample_json),
    .package = "httr2"
  )

  result <- parse_earnings_estimates_response(mock_response, "TEST")

  expect_equal(result$fiscalDateEnding, as.Date(c("2025-09-30", "2025-06-30", "2025-03-31")))
  expect_equal(result$eps_estimate_average, c(3.0, 2.0, 1.0))
})
