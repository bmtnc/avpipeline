#!/bin/bash
# Entrypoint script for ECS tasks
# Routes to the appropriate phase script based on PIPELINE_PHASE env var

set -e

case "${PIPELINE_PHASE}" in
  "phase1")
    echo "Running Phase 1: Fetch"
    exec Rscript /app/scripts/run_phase1_aws.R
    ;;
  "phase2")
    echo "Running Phase 2: Generate"
    exec Rscript /app/scripts/run_phase2_aws.R
    ;;
  "full"|"")
    echo "Running Full Pipeline (Phase 1 + Phase 2)"
    exec Rscript /app/scripts/run_pipeline_aws.R
    ;;
  *)
    echo "Error: Unknown PIPELINE_PHASE '${PIPELINE_PHASE}'"
    echo "Valid values: phase1, phase2, full (default)"
    exit 1
    ;;
esac
