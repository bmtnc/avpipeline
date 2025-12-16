#!/usr/bin/env Rscript

# ============================================================================
# Full Pipeline: Phase 1 + Phase 2
# ============================================================================
# Runs the complete two-phase pipeline:
#   Phase 1: Fetch raw data to S3 (with smart refresh)
#   Phase 2: Generate TTM artifacts from S3 data
#
# This script is the main entry point for the pipeline.
# ============================================================================

message("=", paste(rep("=", 78), collapse = ""))
message("RUNNING FULL PIPELINE")
message("=", paste(rep("=", 78), collapse = ""))
message("")

start_time <- Sys.time()

# ============================================================================
# PHASE 1: FETCH
# ============================================================================

message("Starting Phase 1: Fetch...")
message("")

source(file.path(dirname(sys.frame(1)$ofile), "run_phase1_fetch.R"))

phase1_time <- Sys.time()
phase1_duration <- round(as.numeric(difftime(phase1_time, start_time, units = "mins")), 2)

message("")
message("Phase 1 completed in ", phase1_duration, " minutes")
message("")

# ============================================================================
# PHASE 2: GENERATE
# ============================================================================

message("Starting Phase 2: Generate...")
message("")

source(file.path(dirname(sys.frame(1)$ofile), "run_phase2_generate.R"))

end_time <- Sys.time()
phase2_duration <- round(as.numeric(difftime(end_time, phase1_time, units = "mins")), 2)
total_duration <- round(as.numeric(difftime(end_time, start_time, units = "mins")), 2)

message("")
message("Phase 2 completed in ", phase2_duration, " minutes")
message("")

# ============================================================================
# SUMMARY
# ============================================================================

message("=", paste(rep("=", 78), collapse = ""))
message("FULL PIPELINE COMPLETE")
message("=", paste(rep("=", 78), collapse = ""))
message("  Phase 1 (Fetch): ", phase1_duration, " minutes")
message("  Phase 2 (Generate): ", phase2_duration, " minutes")
message("  Total: ", total_duration, " minutes")
message("")
