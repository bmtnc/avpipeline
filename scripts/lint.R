#!/usr/bin/env Rscript

# Lint the package against .lintr.
#
# Report-only by default: prints a per-linter summary and the lints, but exits 0
# so it doesn't block CI while the pre-existing backlog is triaged. Set
# LINT_STRICT=true to exit non-zero when any lint is found (flip CI to enforcing
# once the backlog is cleared).

lints <- lintr::lint_package()
df <- as.data.frame(lints)

cat(sprintf("Total lints: %d\n\n", nrow(df)))
if (nrow(df) > 0) {
  cat("By linter:\n")
  print(sort(table(df$linter), decreasing = TRUE))
  cat("\n")
  print(lints)
}

strict <- tolower(Sys.getenv("LINT_STRICT", "false")) %in% c("true", "1", "yes")
if (strict && nrow(df) > 0) {
  quit(status = 1L)
}
