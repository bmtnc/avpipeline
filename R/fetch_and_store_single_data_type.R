#' Fetch and Store Single Data Type
#'
#' Fetches a single data type from API and immediately stores to S3.
#'
#' @param ticker character: Stock symbol
#' @param data_type character: Type of data (e.g., "balance_sheet", "price")
#' @param bucket_name character: S3 bucket name
#' @param api_key character: Alpha Vantage API key
#' @param region character: AWS region (default: "us-east-1")
#' @param delay_seconds numeric: Delay after API call (default: 1)
#' @param create_version_snapshot logical: Whether to backup existing data (default: TRUE)
#' @param outputsize character: For price data only - "compact" (100 days) or "full" (20+ years)
#' @return list: success, data, error, and metadata (outputsize_used for price)
#' @keywords internal
fetch_and_store_single_data_type <- function(
  ticker,
  data_type,
  bucket_name,
  api_key,
  region = "us-east-1",
  delay_seconds = 1,
  create_version_snapshot = TRUE,
  outputsize = NULL
) {
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("fetch_and_store_single_data_type(): [ticker] must be a character scalar")
  }
  if (!is.character(data_type) || length(data_type) != 1) {
    stop(
      "fetch_and_store_single_data_type(): [data_type] must be a character scalar"
    )
  }
  if (!is.character(bucket_name) || length(bucket_name) != 1) {
    stop(
      "fetch_and_store_single_data_type(): [bucket_name] must be a character scalar"
    )
  }

  config <- get_config_for_data_type(data_type)
  if (is.null(config)) {
    return(list(
      success = FALSE,
      data = NULL,
      error = paste0("Unknown data_type: ", data_type),
      outputsize_used = NULL
    ))
  }

  tryCatch({
    if (data_type == "price" && !is.null(outputsize)) {
      data <- fetch_single_ticker_data(ticker, config, api_key = api_key, outputsize = outputsize)
    } else {
      data <- fetch_single_ticker_data(ticker, config, api_key = api_key)
    }

    if (is.null(data) || nrow(data) == 0) {
      return(list(
        success = TRUE,
        data = NULL,
        error = NULL,
        outputsize_used = outputsize
      ))
    }

    if (create_version_snapshot) {
      s3_write_version_snapshot(ticker, data_type, bucket_name, region)
    }

    s3_write_ticker_raw_data(data, ticker, data_type, bucket_name, region)

    Sys.sleep(delay_seconds)

    list(
      success = TRUE,
      data = data,
      error = NULL,
      outputsize_used = outputsize
    )
  }, error = function(e) {
    list(
      success = FALSE,
      data = NULL,
      error = conditionMessage(e),
      outputsize_used = outputsize
    )
  })
}
