#' Fetch and Store Interim Daily Quotes
#'
#' Fetches current-day bulk quotes for all symbols (in chunks of 100), normalizes
#' them to the price schema, and accumulates them into the consolidated interim
#' file. Accumulation lets multiple daily runs between weekly reconciliations all
#' contribute bars; the newest pull wins for any repeated (ticker, date).
#'
#' @param symbols character: Ticker symbols to quote
#' @param bucket_name character: S3 bucket name
#' @param api_key character: API key (uses get_api_key() if NULL)
#' @param region character: AWS region (default: "us-east-1")
#' @param chunk_size integer: Symbols per API call (default: 100, the endpoint max)
#' @return tibble: the full accumulated interim store that was written
#' @keywords internal
fetch_and_store_interim_quotes <- function(
  symbols,
  bucket_name,
  api_key = NULL,
  region = "us-east-1",
  chunk_size = 100
) {
  if (!is.character(symbols) || length(symbols) == 0) {
    stop(
      "fetch_and_store_interim_quotes(): [symbols] must be a non-empty character vector"
    )
  }
  validate_character_scalar(bucket_name, name = "bucket_name")

  new_quotes <- symbols %>%
    split(ceiling(seq_along(.) / chunk_size)) %>%
    lapply(function(chunk) {
      tryCatch(
        fetch_bulk_quotes(chunk, api_key = api_key),
        error = function(e) {
          warning("bulk quote chunk failed: ", conditionMessage(e))
          NULL
        }
      )
    }) %>%
    dplyr::bind_rows() %>%
    normalize_bulk_quotes_to_price_schema()

  existing <- s3_read_interim_quotes(bucket_name, region)
  combined <- accumulate_interim_quotes(existing, new_quotes)

  s3_write_interim_quotes(combined, bucket_name, region)

  combined
}
