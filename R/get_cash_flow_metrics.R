#' Get Cash Flow Statement Metrics Vector
#'
#' Returns a character vector containing the standard cash flow statement metrics that are typically
#' aggregated on a trailing twelve months (TTM) basis for financial analysis.
#'
#' @return A character vector of cash flow statement metric names
#' @export
get_cash_flow_metrics <- function() {
  c(
    "operatingCashflow", "paymentsForOperatingActivities", "proceedsFromOperatingActivities",
    "changeInOperatingLiabilities", "changeInOperatingAssets", "depreciationDepletionAndAmortization",
    "capitalExpenditures", "changeInReceivables", "changeInInventory", "profitLoss",
    "cashflowFromInvestment", "cashflowFromFinancing", "proceedsFromRepaymentsOfShortTermDebt",
    "paymentsForRepurchaseOfCommonStock", "paymentsForRepurchaseOfEquity",
    "paymentsForRepurchaseOfPreferredStock", "dividendPayout", "dividendPayoutCommonStock",
    "dividendPayoutPreferredStock", "proceedsFromIssuanceOfCommonStock",
    "proceedsFromIssuanceOfLongTermDebtAndCapitalSecuritiesNet", "proceedsFromIssuanceOfPreferredStock",
    "proceedsFromRepurchaseOfEquity", "proceedsFromSaleOfTreasuryStock",
    "changeInCashAndCashEquivalents", "changeInExchangeRate", "netIncome.cf"
  )
}