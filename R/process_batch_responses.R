#' Parse API Response by Data Type
#'
#' Dispatches to the appropriate parser based on data_type.
#'
#' @param response httr2 response object
#' @param ticker character: Stock ticker symbol
#' @param data_type character: One of "price", "splits", "balance_sheet",
#'   "income_statement", "cash_flow", "earnings"
#' @param extra_params list: Additional parameters (e.g., datatype for price)
#' @return Parsed data (tibble or data.frame)
#' @keywords internal
parse_response_by_type <- function(response, ticker, data_type, extra_params = list()) {
  switch(data_type,
    "price" = parse_price_response(
      response, ticker,
      datatype = extra_params$datatype %||% "json"
    ),
    "splits" = parse_splits_response(response, ticker),
    "balance_sheet" = parse_balance_sheet_response(response, ticker),
    "income_statement" = parse_income_statement_response(response, ticker),
    "cash_flow" = parse_cash_flow_response(response, ticker),
    "earnings" = parse_earnings_response(response, ticker),
    stop("Unknown data_type: ", data_type)
  )
}

#' Process Batch Responses from req_perform_parallel
#'
#' Parses all responses, writes parquet files to a local temp directory,
#' then batch uploads to S3 via `aws s3 cp --recursive`.
#'
#' @param responses list: Responses from httr2::req_perform_parallel()
#' @param request_specs list: Corresponding request specs from build_batch_requests()
#' @param bucket_name character: S3 bucket name
#' @param region character: AWS region
#' @return Named list by ticker, each containing named list by data_type with
#'   success, data, error, outputsize_used
#' @keywords internal
process_batch_responses <- function(responses, request_specs, bucket_name, region) {
  results <- list()
  write_tasks <- list()

  # Phase 1: Parse all responses (fast, CPU-only)
  for (i in seq_along(responses)) {
    resp <- responses[[i]]
    spec <- request_specs[[i]]
    ticker <- spec$ticker
    data_type <- spec$data_type
    extra_params <- spec$extra_params

    if (is.null(results[[ticker]])) {
      results[[ticker]] <- list()
    }

    result <- tryCatch({
      if (inherits(resp, "error")) {
        list(
          success = FALSE,
          data = NULL,
          error = conditionMessage(resp),
          outputsize_used = extra_params$outputsize
        )
      } else {
        data <- parse_response_by_type(resp, ticker, data_type, extra_params)

        if (!is.null(data) && nrow(data) > 0) {
          write_tasks[[length(write_tasks) + 1]] <- list(
            data = data, ticker = ticker, data_type = data_type
          )
        }

        list(
          success = TRUE,
          data = data,
          error = NULL,
          outputsize_used = extra_params$outputsize
        )
      }
    }, error = function(e) {
      list(
        success = FALSE,
        data = NULL,
        error = conditionMessage(e),
        outputsize_used = extra_params$outputsize
      )
    })

    results[[ticker]][[data_type]] <- result
  }

  # Phase 2: Write to local temp dir, then batch upload to S3
  if (length(write_tasks) > 0) {
    temp_dir <- tempfile(pattern = "batch_")
    dir.create(temp_dir, recursive = TRUE)
    on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

    # Write all parquet files locally (fast, disk I/O only)
    for (task in write_tasks) {
      tryCatch({
        s3_key <- generate_raw_data_s3_key(task$ticker, task$data_type)
        local_path <- file.path(temp_dir, s3_key)
        dir.create(dirname(local_path), recursive = TRUE, showWarnings = FALSE)
        arrow::write_parquet(task$data, local_path)
      }, error = function(e) {
        results[[task$ticker]][[task$data_type]]$success <<- FALSE
        results[[task$ticker]][[task$data_type]]$error <<- conditionMessage(e)
      })
    }

    # Batch upload to S3 (AWS CLI uses parallel transfers by default)
    local_raw_dir <- file.path(temp_dir, "raw")
    s3_target <- paste0("s3://", bucket_name, "/raw/")

    sync_result <- system2_with_timeout(
      "aws",
      args = c("s3", "cp", "--recursive", local_raw_dir, s3_target,
               "--region", region, "--only-show-errors"),
      timeout_seconds = 300,
      stdout = TRUE,
      stderr = TRUE
    )

    if (is_timeout_result(sync_result)) {
      for (task in write_tasks) {
        results[[task$ticker]][[task$data_type]]$success <- FALSE
        results[[task$ticker]][[task$data_type]]$error <- "S3 batch upload timed out"
      }
    } else if (!is.null(attr(sync_result, "status")) && attr(sync_result, "status") != 0) {
      for (task in write_tasks) {
        results[[task$ticker]][[task$data_type]]$success <- FALSE
        results[[task$ticker]][[task$data_type]]$error <- paste(
          "S3 batch upload failed:", paste(sync_result, collapse = "\n")
        )
      }
    }
  }

  results
}
