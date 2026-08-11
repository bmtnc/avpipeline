#' Detect Statement Lag Behind Earnings
#'
#' Checks whether any financial statement's latest fiscal quarter trails the
#' earnings endpoint's latest fiscal quarter. AV updates earnings same-day from
#' the press release, but statements can lag by days to weeks; a lagged fetch
#' must stay eligible for re-fetch or stale statements freeze until the next
#' earnings window.
#'
#' @param income_statement data.frame or NULL: Raw income statement data
#' @param balance_sheet data.frame or NULL: Raw balance sheet data
#' @param cash_flow data.frame or NULL: Raw cash flow data
#' @param earnings data.frame or NULL: Raw earnings data
#' @return logical: TRUE if any statement lags earnings' max fiscalDateEnding
#' @keywords internal
detect_statement_lag <- function(
  income_statement,
  balance_sheet,
  cash_flow,
  earnings
) {
  max_fiscal_date <- function(data) {
    if (is.null(data) || nrow(data) == 0) {
      return(as.Date(NA))
    }
    dates <- as.Date(data$fiscalDateEnding)
    if (all(is.na(dates))) {
      return(as.Date(NA))
    }
    max(dates, na.rm = TRUE)
  }

  earnings_max <- max_fiscal_date(earnings)
  if (is.na(earnings_max)) {
    return(FALSE)
  }

  statement_maxes <- c(
    max_fiscal_date(income_statement),
    max_fiscal_date(balance_sheet),
    max_fiscal_date(cash_flow)
  )

  any(is.na(statement_maxes) | statement_maxes < earnings_max)
}
