worker_record <- function(
  ticker,
  status,
  rows = 0L,
  error_message = NA_character_
) {
  list(
    ticker = ticker,
    data = NULL,
    status = status,
    rows = rows,
    error_message = error_message,
    duration_seconds = 1.5
  )
}

test_that("each worker outcome maps to its own log status", {
  results <- list(
    worker_record("AAA", "success", rows = 40L),
    worker_record("BBB", "skipped"),
    worker_record("CCC", "error", error_message = "boom")
  )

  log <- build_phase2_log(results, c("AAA", "BBB", "CCC"))

  expect_equal(nrow(log), 3)
  expect_equal(log$status, c("success", "skipped", "error"))
  expect_equal(log$rows, c(40L, 0L, 0L))
  expect_equal(log$error_message[[3]], "boom")
  expect_true(all(log$phase == "generate"))
  expect_true(all(log$data_type == "quarterly"))
})

test_that("counts derived from the log match the worker outcomes", {
  results <- list(
    worker_record("AAA", "success", rows = 10L),
    worker_record("BBB", "success", rows = 20L),
    worker_record("CCC", "skipped"),
    worker_record("DDD", "error", error_message = "boom")
  )

  log <- build_phase2_log(results, c("AAA", "BBB", "CCC", "DDD"))

  expect_equal(sum(log$status == "success"), 2)
  expect_equal(sum(log$status == "skipped"), 1)
  expect_equal(sum(log$status == "error"), 1)
  expect_equal(sum(log$rows), 30)
})

test_that("a killed worker is logged as an error, not a skip", {
  killed <- structure("Error: cannot allocate vector\n", class = "try-error")
  results <- list(worker_record("AAA", "success", rows = 5L), killed)

  log <- build_phase2_log(results, c("AAA", "BBB"))

  expect_equal(log$status, c("success", "error"))
  expect_equal(log$ticker[[2]], "BBB")
  expect_match(log$error_message[[2]], "worker terminated")
})

test_that("a bare NULL result is logged as an error, not a skip", {
  results <- list(NULL)

  log <- build_phase2_log(results, "AAA")

  expect_equal(log$status, "error")
  expect_match(log$error_message[[1]], "no result record")
})

test_that("empty results give an empty log with the standard schema", {
  log <- build_phase2_log(list(), character(0))

  expect_equal(nrow(log), 0)
  expect_equal(names(log), names(create_pipeline_log()))
})

test_that("mismatched results and tickers error", {
  expect_error(
    build_phase2_log(list(worker_record("AAA", "success")), c("AAA", "BBB")),
    "same length"
  )
})

test_that("non-list results error", {
  expect_error(build_phase2_log("nope", "AAA"), "must be a list")
})
