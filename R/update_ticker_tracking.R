#' Update Tracking for a Single Ticker
#'
#' Updates the tracking dataframe with new values for a ticker.
#'
#' @param tracking tibble: Full refresh tracking dataframe
#' @param ticker character: Stock symbol
#' @param updates list: Named list of columns to update
#' @return tibble: Updated tracking dataframe
#' @keywords internal
update_ticker_tracking <- function(tracking, ticker, updates) {
  if (!is.data.frame(tracking)) {
    stop("update_ticker_tracking(): [tracking] must be a data.frame")
  }
  if (!is.character(ticker) || length(ticker) != 1) {
    stop("update_ticker_tracking(): [ticker] must be a character scalar")
  }
  if (!is.list(updates)) {
    stop("update_ticker_tracking(): [updates] must be a list")
  }

  ticker_exists <- ticker %in% tracking$ticker

  if (!ticker_exists) {
    new_row <- create_default_ticker_tracking(ticker)
    for (col in names(updates)) {
      if (col %in% names(new_row)) {
        new_row[[col]] <- updates[[col]]
      }
    }
    return(dplyr::bind_rows(tracking, new_row))
  }

  for (col in names(updates)) {
    if (col %in% names(tracking)) {
      tracking <- dplyr::mutate(
        tracking,
        !!col := dplyr::if_else(
          ticker == !!ticker,
          updates[[col]],
          .data[[col]]
        )
      )
    }
  }

  tracking
}
