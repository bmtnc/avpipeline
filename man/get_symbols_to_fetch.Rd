% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_symbols_to_fetch.R
\name{get_symbols_to_fetch}
\alias{get_symbols_to_fetch}
\title{Get Symbols to Fetch}
\usage{
get_symbols_to_fetch(requested_symbols, cached_data, symbol_column = NULL)
}
\arguments{
\item{requested_symbols}{Character vector of symbols requested}

\item{cached_data}{Data frame containing cached data with a 'ticker' or 'symbol' column}

\item{symbol_column}{Character. Name of the symbol column in cached_data.
If NULL, will auto-detect 'ticker' or 'symbol' columns.}
}
\value{
Character vector of symbols that need to be fetched
}
\description{
Determines which symbols need to be fetched by comparing requested symbols
against symbols already present in cached data. Returns only the symbols
that are not already cached. Works with both 'ticker' and 'symbol' column names.
}
\examples{
\dontrun{
requested <- c("AAPL", "GOOGL", "MSFT", "TSLA")
cached_data <- read_cached_price_data("cache/price_data.csv")
symbols_to_fetch <- get_symbols_to_fetch(requested, cached_data)
}

}
