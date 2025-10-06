#' Forward Fill Financial Data
#'
#' Forward fills financial data by ticker group using tidyr::fill().
#' This propagates the most recent financial statement values forward to
#' subsequent dates until new financial data is reported.
#'
#' @param data tibble: Data frame with ticker and financial metrics
#' @return tibble: Data frame with forward-filled financial metrics
#' @keywords internal
forward_fill_financial_data <- function(data) {
  # Input validation
  if (!is.data.frame(data)) {
    stop(paste0(
      "forward_fill_financial_data(): [data] must be a data.frame, not ",
      class(data)[1]
    ))
  }
  
  # Validate required column
  if (!"ticker" %in% names(data)) {
    stop(paste0(
      "forward_fill_financial_data(): [data] must contain 'ticker' column"
    ))
  }
  
  # Forward fill by ticker group
  data %>%
    dplyr::group_by(ticker) %>%
    tidyr::fill(dplyr::everything(), .direction = "down") %>%
    dplyr::ungroup()
}
