#' Get a Valid Alpha Vantage API Key
#'
#' @param api_key Character scalar or `NULL`. If `NULL`, fallback to environment
#'   variable `ALPHA_VANTAGE_API_KEY`.
#'
#' @return Character scalar containing a non-empty API key.
#' @export
get_api_key <- function(api_key = NULL) {
  if (is.null(api_key)) {
    api_key <- Sys.getenv("ALPHA_VANTAGE_API_KEY")
  }
  validate_character_scalar(api_key, allow_empty = FALSE, name = "api_key")
  api_key
}
