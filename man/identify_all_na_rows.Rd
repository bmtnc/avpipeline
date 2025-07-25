% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/identify_all_na_rows.R
\name{identify_all_na_rows}
\alias{identify_all_na_rows}
\title{Remove Rows with All NA Financial Columns}
\usage{
identify_all_na_rows(data, financial_cols, statement_type)
}
\arguments{
\item{data}{A data frame containing financial data}

\item{financial_cols}{Character vector of column names representing financial metrics}

\item{statement_type}{Character string describing the type of financial statement for reporting}
}
\value{
A data frame with rows containing all NA financial columns removed
}
\description{
Identifies and removes observations where all financial metric columns contain NA values,
keeping only records that have at least some financial data available. Reports details
about removed observations for data quality monitoring.
}
