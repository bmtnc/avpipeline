% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calculate_baseline_stats.R
\name{calculate_baseline_stats}
\alias{calculate_baseline_stats}
\title{Calculate Baseline Statistics for Anomaly Detection}
\usage{
calculate_baseline_stats(values, indices)
}
\arguments{
\item{values}{Numeric vector of time series values}

\item{indices}{Integer vector of indices to use for baseline calculation}
}
\value{
Named list with baseline_median and baseline_mad values
}
\description{
Calculates median and MAD (Median Absolute Deviation) statistics from baseline values
for use in anomaly detection.
}
