# =============================================================================
# Unified Financial Artifact Explorer
# =============================================================================
#
# Simple exploration script to load and visualize the unified financial artifact
# Demonstrates plotting capabilities with EBITDA per share for MSFT
#
# =============================================================================

# ---- SECTION 2: Load unified financial artifact -----------------------------
cat("Loading unified financial artifact ...\n")

unified_final <- read_cached_data(
  "cache/unified_financial_artifact.csv",
  date_columns = c("date", "fiscalDateEnding", "reportedDate", "as_of_date", "calendar_quarter_ending")
)

cat("Loaded dataset: ", nrow(unified_final), " rows, ", ncol(unified_final), " columns\n")

# ---- SECTION 3: Create visualization ----------------------------------------
cat("Creating EBITDA per share plot for MSFT ...\n")

df <- unified_final %>% 
  dplyr::filter(
    ticker == "MSFT",
    has_complete_financial_data
  )

create_bar_plot(
  df,
  date_col = "date",
  ticker_col = "ticker",
  value_col = "ebitda_per_share"
)

cat("Plot created successfully!\n")