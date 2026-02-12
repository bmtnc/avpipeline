test_that("parse_historical_options_response parses JSON correctly", {
  sample_json <- jsonlite::toJSON(list(
    endpoint = "Historical Options",
    message = "success",
    data = data.frame(
      contractID = c("AAPL260220C00200000", "AAPL260220P00200000"),
      symbol = c("AAPL", "AAPL"),
      expiration = c("2026-02-20", "2026-02-20"),
      strike = c("200.00", "200.00"),
      type = c("call", "put"),
      last = c("45.50", "1.20"),
      mark = c("46.00", "1.15"),
      bid = c("45.00", "1.10"),
      bid_size = c("10", "20"),
      ask = c("47.00", "1.20"),
      ask_size = c("15", "25"),
      volume = c("100", "50"),
      open_interest = c("500", "300"),
      date = c("2026-02-11", "2026-02-11"),
      implied_volatility = c("0.32500", "0.33000"),
      delta = c("0.85000", "-0.15000"),
      gamma = c("0.01200", "0.01200"),
      theta = c("-0.15000", "-0.10000"),
      vega = c("0.25000", "0.25000"),
      rho = c("0.05000", "-0.05000"),
      stringsAsFactors = FALSE
    )
  ), auto_unbox = TRUE)

  mock_response <- structure(
    list(body = charToRaw(as.character(sample_json))),
    class = "httr2_response"
  )
  # Stub resp_body_string to return our JSON
  local_mocked_bindings(
    resp_body_string = function(response) as.character(sample_json),
    .package = "httr2"
  )

  result <- parse_historical_options_response(mock_response, "AAPL", datatype = "json")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(result$ticker, c("AAPL", "AAPL"))
  expect_s3_class(result$date, "Date")
  expect_s3_class(result$expiration, "Date")
  expect_equal(result$date, rep(as.Date("2026-02-11"), 2))
  expect_equal(result$expiration, rep(as.Date("2026-02-20"), 2))
  expect_equal(result$strike, c(200, 200))
  expect_equal(result$type, c("call", "put"))
  expect_type(result$implied_volatility, "double")
  expect_equal(result$implied_volatility, c(0.325, 0.33))
  expect_type(result$delta, "double")
  expect_type(result$volume, "integer")
  expect_type(result$bid_size, "integer")
})

test_that("parse_historical_options_response parses CSV correctly", {
  csv_content <- paste(
    "contractID,symbol,expiration,strike,type,last,mark,bid,bid_size,ask,ask_size,volume,open_interest,date,implied_volatility,delta,gamma,theta,vega,rho",
    "AAPL260220C00200000,AAPL,2026-02-20,200.00,call,45.50,46.00,45.00,10,47.00,15,100,500,2026-02-11,0.32500,0.85000,0.01200,-0.15000,0.25000,0.05000",
    "AAPL260220P00200000,AAPL,2026-02-20,200.00,put,1.20,1.15,1.10,20,1.20,25,50,300,2026-02-11,0.33000,-0.15000,0.01200,-0.10000,0.25000,-0.05000",
    sep = "\n"
  )

  mock_response <- structure(
    list(body = charToRaw(csv_content)),
    class = "httr2_response"
  )
  local_mocked_bindings(
    resp_body_string = function(response) csv_content,
    .package = "httr2"
  )

  result <- parse_historical_options_response(mock_response, "AAPL", datatype = "csv")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(result$ticker, c("AAPL", "AAPL"))
  expect_s3_class(result$date, "Date")
  expect_equal(result$strike, c(200, 200))
  expect_equal(result$implied_volatility, c(0.325, 0.33))
})

test_that("parse_historical_options_response returns empty tibble for empty JSON data", {
  empty_json <- jsonlite::toJSON(list(
    endpoint = "Historical Options",
    message = "success",
    data = list()
  ), auto_unbox = TRUE)

  mock_response <- structure(
    list(body = charToRaw(as.character(empty_json))),
    class = "httr2_response"
  )
  local_mocked_bindings(
    resp_body_string = function(response) as.character(empty_json),
    .package = "httr2"
  )

  result <- parse_historical_options_response(mock_response, "AAPL", datatype = "json")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_true("ticker" %in% names(result))
  expect_true("implied_volatility" %in% names(result))
})

test_that("parse_historical_options_response returns empty tibble for empty CSV", {
  mock_response <- structure(
    list(body = charToRaw("")),
    class = "httr2_response"
  )
  local_mocked_bindings(
    resp_body_string = function(response) "",
    .package = "httr2"
  )

  result <- parse_historical_options_response(mock_response, "AAPL", datatype = "csv")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("parse_historical_options_response propagates API errors", {
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
    parse_historical_options_response(mock_response, "AAPL", datatype = "json"),
    "Alpha Vantage API error"
  )
})

test_that("parse_historical_options_response errors on invalid datatype", {
  mock_response <- structure(list(), class = "httr2_response")
  expect_error(
    parse_historical_options_response(mock_response, "AAPL", datatype = "xml"),
    "datatype must be"
  )
})

test_that("parse_historical_options_response has correct column order", {
  csv_content <- paste(
    "contractID,symbol,expiration,strike,type,last,mark,bid,bid_size,ask,ask_size,volume,open_interest,date,implied_volatility,delta,gamma,theta,vega,rho",
    "TEST260220C00100000,TEST,2026-02-20,100.00,call,5.00,5.10,5.00,10,5.20,15,100,500,2026-02-11,0.30000,0.50000,0.02000,-0.05000,0.20000,0.03000",
    sep = "\n"
  )

  mock_response <- structure(list(), class = "httr2_response")
  local_mocked_bindings(
    resp_body_string = function(response) csv_content,
    .package = "httr2"
  )

  result <- parse_historical_options_response(mock_response, "TEST", datatype = "csv")

  expected_cols <- c(
    "ticker", "contractID", "date", "expiration", "strike", "type",
    "last", "mark", "bid", "bid_size", "ask", "ask_size",
    "volume", "open_interest",
    "implied_volatility", "delta", "gamma", "theta", "vega", "rho"
  )
  expect_equal(names(result), expected_cols)
})
