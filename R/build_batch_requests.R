#' Get Alpha Vantage API Function Name for Data Type
#'
#' @param data_type character: One of "price", "splits", "balance_sheet",
#'   "income_statement", "cash_flow", "earnings"
#' @return character: The Alpha Vantage API function name
#' @keywords internal
get_api_function_for_data_type <- function(data_type) {
  validate_character_scalar(data_type, name = "data_type")

  mapping <- c(
    price = "TIME_SERIES_DAILY_ADJUSTED",
    splits = "SPLITS",
    balance_sheet = "BALANCE_SHEET",
    income_statement = "INCOME_STATEMENT",
    cash_flow = "CASH_FLOW",
    earnings = "EARNINGS"
  )

  if (!data_type %in% names(mapping)) {
    stop("Unknown data_type: ", data_type,
         ". Must be one of: ", paste(names(mapping), collapse = ", "))
  }

  mapping[[data_type]]
}

#' Build Batch Requests for Multiple Tickers
#'
#' Takes a batch plan and returns a flat list of request specs for use with
#' httr2::req_perform_parallel().
#'
#' @param batch_plan named list: Keyed by ticker, each element a list with
#'   fetch_requirements and ticker_tracking
#' @param api_key character: Alpha Vantage API key
#' @param throttle_capacity numeric: Token bucket capacity (default: 1)
#' @param throttle_fill_time numeric: Seconds to refill one token (default: 1)
#' @return list of request specs, each containing: request, ticker, data_type, extra_params
#' @keywords internal
build_batch_requests <- function(batch_plan, api_key,
                                 throttle_capacity = 1,
                                 throttle_fill_time = 1) {
  validate_character_scalar(api_key, name = "api_key")

  if (length(batch_plan) == 0) {
    return(list())
  }

  request_specs <- list()

  for (ticker in names(batch_plan)) {
    plan <- batch_plan[[ticker]]
    fetch_requirements <- plan$fetch_requirements

    if (isTRUE(fetch_requirements$price)) {
      api_function <- get_api_function_for_data_type("price")
      extra_params <- list(outputsize = "full", datatype = "json")
      req <- build_av_request(
        ticker, api_function, api_key,
        throttle_capacity = throttle_capacity,
        throttle_fill_time = throttle_fill_time,
        outputsize = "full", datatype = "json"
      )
      request_specs[[length(request_specs) + 1]] <- list(
        request = req,
        ticker = ticker,
        data_type = "price",
        extra_params = extra_params
      )
    }

    if (isTRUE(fetch_requirements$splits)) {
      api_function <- get_api_function_for_data_type("splits")
      req <- build_av_request(
        ticker, api_function, api_key,
        throttle_capacity = throttle_capacity,
        throttle_fill_time = throttle_fill_time
      )
      request_specs[[length(request_specs) + 1]] <- list(
        request = req,
        ticker = ticker,
        data_type = "splits",
        extra_params = list()
      )
    }

    if (isTRUE(fetch_requirements$quarterly)) {
      quarterly_types <- c("balance_sheet", "income_statement", "cash_flow", "earnings")
      for (data_type in quarterly_types) {
        api_function <- get_api_function_for_data_type(data_type)
        req <- build_av_request(
          ticker, api_function, api_key,
          throttle_capacity = throttle_capacity,
          throttle_fill_time = throttle_fill_time
        )
        request_specs[[length(request_specs) + 1]] <- list(
          request = req,
          ticker = ticker,
          data_type = data_type,
          extra_params = list()
        )
      }
    }
  }

  request_specs
}
