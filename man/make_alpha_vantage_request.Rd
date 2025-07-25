% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/make_alpha_vantage_request.R
\name{make_alpha_vantage_request}
\alias{make_alpha_vantage_request}
\title{Generic Alpha Vantage API Request Function}
\usage{
make_alpha_vantage_request(ticker, config, api_key = NULL, ...)
}
\arguments{
\item{ticker}{Character. The equity ticker symbol}

\item{config}{List. Configuration object defining the API function and parameters}

\item{api_key}{Character. Alpha Vantage API key. If NULL, will use get_api_key()}

\item{...}{Additional parameters passed to the API (e.g., outputsize, datatype)}
}
\value{
Raw httr response object
}
\description{
Makes HTTP requests to the Alpha Vantage API for any supported data type.
This function replaces all individual API request functions by using
configuration objects to determine the appropriate parameters.
}
\keyword{internal}
