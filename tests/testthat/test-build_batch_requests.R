# Tests for build_batch_requests and get_api_function_for_data_type

# --- get_api_function_for_data_type ---

test_that("get_api_function_for_data_type returns correct mappings", {
  expect_equal(get_api_function_for_data_type("price"), "TIME_SERIES_DAILY_ADJUSTED")
  expect_equal(get_api_function_for_data_type("splits"), "SPLITS")
  expect_equal(get_api_function_for_data_type("balance_sheet"), "BALANCE_SHEET")
  expect_equal(get_api_function_for_data_type("income_statement"), "INCOME_STATEMENT")
  expect_equal(get_api_function_for_data_type("cash_flow"), "CASH_FLOW")
  expect_equal(get_api_function_for_data_type("earnings"), "EARNINGS")
})

test_that("get_api_function_for_data_type errors on unknown data_type", {
  expect_error(get_api_function_for_data_type("overview"), "Unknown data_type")
  expect_error(get_api_function_for_data_type(""), "Unknown data_type")
  expect_error(get_api_function_for_data_type("PRICE"), "Unknown data_type")
})

test_that("get_api_function_for_data_type validates input type", {
  expect_error(get_api_function_for_data_type(123), "data_type.*character scalar")
  expect_error(get_api_function_for_data_type(NULL), "data_type.*character scalar")
  expect_error(get_api_function_for_data_type(c("price", "splits")), "data_type.*character scalar")
})

# --- build_batch_requests ---

test_that("build_batch_requests generates correct count for full fetch", {
  batch_plan <- list(
    AAPL = list(
      fetch_requirements = list(price = TRUE, splits = TRUE, quarterly = TRUE),
      ticker_tracking = NULL
    )
  )

  specs <- build_batch_requests(batch_plan, "test_key")

  # price + splits + 4 quarterly (balance_sheet, income_statement, cash_flow, earnings)
  expect_length(specs, 6)
})

test_that("build_batch_requests generates correct count for price+splits only", {
  batch_plan <- list(
    AAPL = list(
      fetch_requirements = list(price = TRUE, splits = TRUE, quarterly = FALSE),
      ticker_tracking = NULL
    )
  )

  specs <- build_batch_requests(batch_plan, "test_key")
  expect_length(specs, 2)
})

test_that("build_batch_requests generates correct count for quarterly only", {
  batch_plan <- list(
    AAPL = list(
      fetch_requirements = list(price = FALSE, splits = FALSE, quarterly = TRUE),
      ticker_tracking = NULL
    )
  )

  specs <- build_batch_requests(batch_plan, "test_key")
  expect_length(specs, 4)
})

test_that("build_batch_requests handles multiple tickers", {
  batch_plan <- list(
    AAPL = list(
      fetch_requirements = list(price = TRUE, splits = TRUE, quarterly = FALSE),
      ticker_tracking = NULL
    ),
    MSFT = list(
      fetch_requirements = list(price = TRUE, splits = TRUE, quarterly = TRUE),
      ticker_tracking = NULL
    )
  )

  specs <- build_batch_requests(batch_plan, "test_key")
  # AAPL: 2, MSFT: 6
  expect_length(specs, 8)

  # Check ticker/data_type metadata preserved
  tickers <- sapply(specs, function(s) s$ticker)
  expect_equal(sum(tickers == "AAPL"), 2)
  expect_equal(sum(tickers == "MSFT"), 6)
})

test_that("build_batch_requests returns empty list for empty batch plan", {
  specs <- build_batch_requests(list(), "test_key")
  expect_length(specs, 0)
})

test_that("build_batch_requests preserves data_type metadata", {
  batch_plan <- list(
    AAPL = list(
      fetch_requirements = list(price = TRUE, splits = TRUE, quarterly = TRUE),
      ticker_tracking = NULL
    )
  )

  specs <- build_batch_requests(batch_plan, "test_key")
  data_types <- sapply(specs, function(s) s$data_type)

  expect_true("price" %in% data_types)
  expect_true("splits" %in% data_types)
  expect_true("balance_sheet" %in% data_types)
  expect_true("income_statement" %in% data_types)
  expect_true("cash_flow" %in% data_types)
  expect_true("earnings" %in% data_types)
})

test_that("build_batch_requests includes outputsize for price", {
  batch_plan <- list(
    AAPL = list(
      fetch_requirements = list(price = TRUE, splits = FALSE, quarterly = FALSE),
      ticker_tracking = NULL
    )
  )

  specs <- build_batch_requests(batch_plan, "test_key")
  expect_equal(specs[[1]]$extra_params$outputsize, "full")
})

test_that("build_batch_requests returns httr2_request objects", {
  batch_plan <- list(
    AAPL = list(
      fetch_requirements = list(price = TRUE, splits = FALSE, quarterly = FALSE),
      ticker_tracking = NULL
    )
  )

  specs <- build_batch_requests(batch_plan, "test_key")
  expect_s3_class(specs[[1]]$request, "httr2_request")
})

test_that("build_batch_requests skips tickers with nothing to fetch", {
  batch_plan <- list(
    AAPL = list(
      fetch_requirements = list(price = FALSE, splits = FALSE, quarterly = FALSE),
      ticker_tracking = NULL
    )
  )

  specs <- build_batch_requests(batch_plan, "test_key")
  expect_length(specs, 0)
})
