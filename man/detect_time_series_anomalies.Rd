% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/detect_time_series_anomalies.R
\name{detect_time_series_anomalies}
\alias{detect_time_series_anomalies}
\title{Detect Anomalous Values in Time Series Using Mean Absolute Deviation}
\usage{
detect_time_series_anomalies(values, threshold = 3, min_observations = 10)
}
\arguments{
\item{values}{Numeric vector of time series values to analyze for anomalies}

\item{threshold}{Numeric value specifying the MAD threshold multiplier (default: 3)}

\item{min_observations}{Integer specifying minimum number of observations required for MAD calculation (default: 10)}
}
\value{
Logical vector of same length as input, with TRUE indicating anomalous values
}
\description{
Calculates anomaly flags for time series values using Mean Absolute Deviation (MAD) threshold.
Values that exceed the MAD threshold relative to the historical median are flagged as anomalous.
}
