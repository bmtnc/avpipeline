test_that("equities_taxonomy has the expected structure; industry is the uppercase join key", {
  tax <- equities_taxonomy()
  expect_equal(names(tax), c("sector", "subsector", "industry"))
  expect_gt(nrow(tax), 100)
  # industry is the join key against Alpha Vantage data and must match its UPPERCASE
  expect_equal(tax$industry, toupper(tax$industry))
  expect_equal(tax$sector, toupper(tax$sector))
})

test_that("each industry maps to exactly one subsector", {
  tax <- equities_taxonomy()
  per_industry <- tapply(tax$subsector, tax$industry, function(x) {
    length(unique(x))
  })
  expect_true(all(per_industry == 1))
})

test_that("join_equities_taxonomy adds subsector keyed on industry", {
  # nolint start
  # fmt: skip
  data <- tibble::tribble(
    ~ticker, ~industry,
    "AAPL",  "CONSUMER ELECTRONICS",
    "JPM",   "BANKS - DIVERSIFIED"
  )
  # nolint end
  result <- join_equities_taxonomy(data)

  expect_true("subsector" %in% names(result))
  expect_equal(result$subsector, c("HARDWARE", "BANKING"))
  expect_equal(nrow(result), 2)
})

test_that("diversified real estate and infrastructure industries map to a subsector", {
  # nolint start
  # fmt: skip
  data <- tibble::tribble(
    ~ticker, ~industry,
    "JOE",   "REAL ESTATE - DIVERSIFIED",
    "BEEP",  "INFRASTRUCTURE OPERATIONS"
  )
  # nolint end
  result <- join_equities_taxonomy(data)
  expect_equal(result$subsector, c("REAL ESTATE SERVICES", "INDUSTRIAL SERVICES"))
})

test_that("unmapped or NA industry yields NA subsector", {
  # nolint start
  # fmt: skip
  data <- tibble::tribble(
    ~ticker, ~industry,
    "BABA",  NA_character_,
    "ZZZ",   "NOT A REAL INDUSTRY"
  )
  # nolint end
  result <- join_equities_taxonomy(data)
  expect_true(all(is.na(result$subsector)))
})

test_that("errors when industry column is missing", {
  expect_error(join_equities_taxonomy(tibble::tibble(ticker = "AAPL")))
})
