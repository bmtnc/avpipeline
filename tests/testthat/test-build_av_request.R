# Tests for build_av_request

test_that("build_av_request returns httr2_request object", {
  req <- build_av_request("AAPL", "TIME_SERIES_DAILY_ADJUSTED", "test_key")
  expect_s3_class(req, "httr2_request")
})

test_that("build_av_request includes correct URL query params", {
  req <- build_av_request("AAPL", "TIME_SERIES_DAILY_ADJUSTED", "test_key")
  url <- req$url
  expect_true(grepl("function=TIME_SERIES_DAILY_ADJUSTED", url))
  expect_true(grepl("symbol=AAPL", url))
  expect_true(grepl("apikey=test_key", url))
})

test_that("build_av_request passes additional params", {
  req <- build_av_request("AAPL", "TIME_SERIES_DAILY_ADJUSTED", "test_key",
                          outputsize = "full", datatype = "json")
  url <- req$url
  expect_true(grepl("outputsize=full", url))
  expect_true(grepl("datatype=json", url))
})

test_that("build_av_request validates ticker is character scalar", {
  expect_error(build_av_request(123, "FUNC", "key"), "ticker.*character scalar")
  expect_error(build_av_request(c("A", "B"), "FUNC", "key"), "ticker.*character scalar")
  expect_error(build_av_request(NULL, "FUNC", "key"), "ticker.*character scalar")
})

test_that("build_av_request validates api_function is character scalar", {
  expect_error(build_av_request("AAPL", 123, "key"), "api_function.*character scalar")
  expect_error(build_av_request("AAPL", NULL, "key"), "api_function.*character scalar")
})

test_that("build_av_request validates api_key is character scalar", {
  expect_error(build_av_request("AAPL", "FUNC", 123), "api_key.*character scalar")
  expect_error(build_av_request("AAPL", "FUNC", NULL), "api_key.*character scalar")
})

# --- Webfakes throttle tests ---

test_that("req_throttle limits rate with req_perform_parallel", {
  skip_if_not_installed("webfakes")

  app <- webfakes::new_app()
  app$get("/query", function(req, res) {
    Sys.sleep(0.02)
    res$send_json(list(ok = TRUE))
  })
  server <- webfakes::local_app_process(app)

  # Build 6 requests at capacity=1 (1 req/sec)
  requests <- lapply(1:6, function(i) {
    httr2::request(server$url("/query")) %>%
      httr2::req_throttle(capacity = 1, fill_time_s = 1, realm = "av_test_par")
  })

  start <- Sys.time()
  responses <- httr2::req_perform_parallel(requests, max_active = 5)
  duration <- as.numeric(difftime(Sys.time(), start, units = "secs"))

  # 6 requests at 1/s: first 1 instant, then 5 more at 1/s = ~5s
  expect_gte(duration, 4.0)
  expect_length(responses, 6)
})

test_that("max_active does not bypass throttle", {
  skip_if_not_installed("webfakes")

  app <- webfakes::new_app()
  app$get("/query", function(req, res) {
    Sys.sleep(0.02)
    res$send_json(list(ok = TRUE))
  })
  server <- webfakes::local_app_process(app)

  # Build 4 requests with capacity=1, max_active=10
  requests <- lapply(1:4, function(i) {
    httr2::request(server$url("/query")) %>%
      httr2::req_throttle(capacity = 1, fill_time_s = 1, realm = "av_test_max")
  })

  start <- Sys.time()
  responses <- httr2::req_perform_parallel(requests, max_active = 10)
  duration <- as.numeric(difftime(Sys.time(), start, units = "secs"))

  # Even with max_active=10, throttle limits to 1/s
  # Allow timing variance in CI environments
  expect_gte(duration, 2.0)
  expect_length(responses, 4)
})

test_that("token bucket allows initial burst up to capacity", {
  skip_if_not_installed("webfakes")

  app <- webfakes::new_app()
  app$get("/query", function(req, res) {
    Sys.sleep(0.02)
    res$send_json(list(ok = TRUE))
  })
  server <- webfakes::local_app_process(app)

  # Build exactly capacity number of requests
  requests <- lapply(1:5, function(i) {
    httr2::request(server$url("/query")) %>%
      httr2::req_throttle(capacity = 5, fill_time_s = 1, realm = "av_test_burst")
  })

  start <- Sys.time()
  responses <- httr2::req_perform_parallel(requests, max_active = 5)
  duration <- as.numeric(difftime(Sys.time(), start, units = "secs"))

  # With burst capacity=5, first 5 requests should be fast
  expect_lt(duration, 0.5)
  expect_length(responses, 5)
})
