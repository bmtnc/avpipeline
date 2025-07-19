#' Get Balance Sheet Metrics Vector
#'
#' Returns a character vector containing the standard balance sheet metrics that are point-in-time
#' stock measures and should not be aggregated on a trailing twelve months (TTM) basis.
#'
#' @return A character vector of balance sheet metric names
#' @export
get_balance_sheet_metrics <- function() {
  c(
    "totalAssets", "totalCurrentAssets", "cashAndCashEquivalentsAtCarryingValue",
    "cashAndShortTermInvestments", "inventory", "currentNetReceivables", "totalNonCurrentAssets",
    "propertyPlantEquipment", "accumulatedDepreciationAmortizationPPE", "intangibleAssets",
    "intangibleAssetsExcludingGoodwill", "goodwill", "investments", "longTermInvestments",
    "shortTermInvestments", "otherCurrentAssets", "otherNonCurrentAssets", "totalLiabilities",
    "totalCurrentLiabilities", "currentAccountsPayable", "deferredRevenue", "currentDebt",
    "shortTermDebt", "totalNonCurrentLiabilities", "capitalLeaseObligations", "longTermDebt",
    "currentLongTermDebt", "longTermDebtNoncurrent", "shortLongTermDebtTotal",
    "otherCurrentLiabilities", "otherNonCurrentLiabilities", "totalShareholderEquity",
    "treasuryStock", "retainedEarnings", "commonStock", "commonStockSharesOutstanding"
  )
}