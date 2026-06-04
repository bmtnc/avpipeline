# Layer 1 Parity: REALTIME_BULK_QUOTES vs TIME_SERIES_DAILY_ADJUSTED
#
# Confirms that a bulk quote's raw bar matches the canonical daily-adjusted bar
# (the ground-truth endpoint the pipeline is built on). Run this before promoting
# bulk quotes onto the daily price path, and as an ongoing canary afterward.
#
# Two independent checks:
#   1. previous_close parity  — bulk `previous_close` vs the prior trading day's
#      raw daily close. Works ANY time of day (no settlement needed).
#   2. same-day OHLCV parity  — bulk open/high/low/close/volume vs the canonical
#      bar for the same date. Only meaningful AFTER the daily series settles
#      today's bar (run after market close); reported as PENDING otherwise.
#
# Comparison is on RAW close (not adjusted_close): bulk quotes are unadjusted,
# and the pipeline stores raw `close` alongside `adjusted_close`.

# ── Configuration ────────────────────────────────────────────────────────────
SAMPLE_TICKERS <- c(
  "MSFT",
  "AAPL",
  "IBM",
  "NVDA",
  "JPM",
  "XOM",
  "WMT",
  "KO",
  "PG",
  "DIS"
)
PRICE_TOLERANCE <- 1e-4 # absolute $; settled-bar PASS threshold
INTRADAY_BAND <- 0.02 # relative; OHLC drift tolerated for an intraday (pre-close) run
# ──────────────────────────────────────────────────────────────────────────────

devtools::load_all(quiet = TRUE)

cat(
  "Fetching bulk quotes (",
  length(SAMPLE_TICKERS),
  " symbols, 1 call)...\n",
  sep = ""
)
bulk <- SAMPLE_TICKERS %>%
  split(ceiling(seq_along(.) / 100)) %>%
  lapply(fetch_bulk_quotes) %>%
  dplyr::bind_rows()

cat(
  "Fetching canonical daily-adjusted series (",
  length(SAMPLE_TICKERS),
  " calls)...\n",
  sep = ""
)
daily_all <- SAMPLE_TICKERS %>%
  rlang::set_names() %>%
  lapply(function(tk) {
    tryCatch(
      fetch_price(tk, outputsize = "compact", datatype = "json"),
      error = function(e) {
        message("  daily fetch failed for ", tk, ": ", conditionMessage(e))
        NULL
      }
    )
  }) %>%
  dplyr::bind_rows()

# ── Check 1: previous_close vs prior trading day's raw daily close ────────────
prior_close <- bulk %>%
  dplyr::select(ticker, bulk_date = date) %>%
  dplyr::inner_join(daily_all, by = "ticker") %>%
  dplyr::filter(date < bulk_date) %>%
  dplyr::group_by(ticker) %>%
  dplyr::slice_max(date, n = 1, with_ties = FALSE) %>%
  dplyr::ungroup() %>%
  dplyr::select(ticker, prior_date = date, daily_prior_close = close)

prev_check <- bulk %>%
  dplyr::select(ticker, bulk_date = date, bulk_prev_close = previous_close) %>%
  dplyr::left_join(prior_close, by = "ticker") %>%
  dplyr::mutate(
    abs_diff = abs(bulk_prev_close - daily_prior_close),
    status = dplyr::case_when(
      is.na(daily_prior_close) ~ "NO_DAILY_DATA",
      abs_diff <= PRICE_TOLERANCE ~ "PASS",
      TRUE ~ "FAIL"
    )
  )

# ── Check 2: same-day bulk OHLCV vs canonical same-day bar ────────────────────
# A realtime quote is always TODAY's forming bar, so same-day OHLCV is only
# authoritative once that bar settles (after close). Classify:
#   PASS           — settled-bar exact match (prices within PRICE_TOLERANCE)
#   INTRADAY_DRIFT — within INTRADAY_BAND; expected when run pre-close, NOT a bug
#   FAIL           — beyond the band: a genuine scale/mapping break (e.g. split)
# Volume is reported as a relative diff but never flips the verdict (consolidated
# vs primary feeds differ; intraday volume is still accumulating).
sameday_check <- bulk %>%
  dplyr::select(
    ticker,
    date,
    b_open = open,
    b_high = high,
    b_low = low,
    b_close = close,
    b_volume = volume
  ) %>%
  dplyr::left_join(
    daily_all %>%
      dplyr::select(
        ticker,
        date,
        d_open = open,
        d_high = high,
        d_low = low,
        d_close = close,
        d_volume = volume
      ),
    by = c("ticker", "date")
  ) %>%
  dplyr::mutate(
    close_abs_diff = abs(b_close - d_close),
    ohlc_rel_diff = pmax(
      abs(b_open - d_open) / d_open,
      abs(b_high - d_high) / d_high,
      abs(b_low - d_low) / d_low,
      abs(b_close - d_close) / d_close
    ),
    volume_rel_diff = abs(b_volume - d_volume) / d_volume,
    status = dplyr::case_when(
      is.na(d_close) ~ "PENDING_SETTLEMENT",
      close_abs_diff <= PRICE_TOLERANCE ~ "PASS",
      ohlc_rel_diff <= INTRADAY_BAND ~ "INTRADAY_DRIFT",
      TRUE ~ "FAIL"
    )
  )

# ── Report ────────────────────────────────────────────────────────────────────
cat("\n", strrep("=", 70), "\n", sep = "")
cat(
  "LAYER 1 PARITY REPORT  (bulk date: ",
  as.character(bulk$date[1]),
  ", tolerance: ",
  PRICE_TOLERANCE,
  ")\n",
  sep = ""
)
cat(strrep("=", 70), "\n\n", sep = "")

cat("Check 1 — previous_close vs prior daily close (settlement-independent):\n")
print(prev_check, n = Inf)

cmp1 <- prev_check %>% dplyr::filter(status != "NO_DAILY_DATA")
verdict1 <- all.equal(
  cmp1$bulk_prev_close,
  cmp1$daily_prior_close,
  tolerance = PRICE_TOLERANCE
)
cat(
  "\n  all.equal: ",
  if (isTRUE(verdict1)) "TRUE" else paste(verdict1, collapse = "; "),
  "\n",
  sep = ""
)
cat(
  "  ",
  sum(prev_check$status == "PASS"),
  " PASS / ",
  sum(prev_check$status == "FAIL"),
  " FAIL / ",
  sum(prev_check$status == "NO_DAILY_DATA"),
  " no-data\n\n",
  sep = ""
)

cat(
  "Check 2 — same-day OHLCV vs canonical bar (authoritative only post-close):\n"
)
sameday_check %>%
  dplyr::select(
    ticker,
    date,
    b_close,
    d_close,
    ohlc_rel_diff,
    volume_rel_diff,
    status
  ) %>%
  print(n = Inf)

n_pass <- sum(sameday_check$status == "PASS")
n_fail <- sum(sameday_check$status == "FAIL")
n_drift <- sum(sameday_check$status == "INTRADAY_DRIFT")
n_pend <- sum(sameday_check$status == "PENDING_SETTLEMENT")

settled <- sameday_check %>% dplyr::filter(status == "PASS")
if (nrow(settled) > 0) {
  verdict2 <- all.equal(
    settled$b_close,
    settled$d_close,
    tolerance = PRICE_TOLERANCE
  )
  cat(
    "\n  settled-bar close all.equal: ",
    if (isTRUE(verdict2)) "TRUE" else paste(verdict2, collapse = "; "),
    "\n",
    sep = ""
  )
}
if (n_fail == 0 && n_drift > 0) {
  cat(
    "\n  No FAILs. ",
    n_drift,
    " row(s) within the intraday band — expected for a\n",
    "  pre-close run; price scale agrees. Re-run after close for the exact gate.\n",
    sep = ""
  )
}
cat(
  "  ",
  n_pass,
  " PASS / ",
  n_fail,
  " FAIL / ",
  n_drift,
  " intraday-drift / ",
  n_pend,
  " pending\n",
  sep = ""
)
