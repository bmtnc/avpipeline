#' Get Income Statement Metrics Vector
#'
#' Returns a character vector containing the standard income statement metrics that are typically
#' aggregated on a trailing twelve months (TTM) basis for financial analysis.
#'
#' @return A character vector of income statement metric names
#' @export
get_income_statement_metrics <- function() {
  c(
    "grossProfit", "totalRevenue", "costOfRevenue", "costofGoodsAndServicesSold",
    "operatingIncome", "sellingGeneralAndAdministrative", "researchAndDevelopment",
    "operatingExpenses", "investmentIncomeNet", "netInterestIncome", "interestIncome",
    "interestExpense", "nonInterestIncome", "otherNonOperatingIncome", "depreciation",
    "depreciationAndAmortization", "incomeBeforeTax", "incomeTaxExpense",
    "interestAndDebtExpense", "netIncomeFromContinuingOperations", "comprehensiveIncomeNetOfTax",
    "ebit", "ebitda", "netIncome"
  )
}