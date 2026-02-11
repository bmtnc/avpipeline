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
#' Iterates over responses, parses each, writes to S3, and returns per-ticker results.
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
          s3_write_ticker_raw_data(data, ticker, data_type, bucket_name, region)
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

  results
}
