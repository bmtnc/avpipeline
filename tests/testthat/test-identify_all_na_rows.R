# Test data setup
test_df <- tibble::tribble(
  ~ticker, ~fiscalDateEnding, ~revenue, ~expenses, ~profit,
  "AAPL", as.Date("2023-12-31"), 100, 80, 20,
  "AAPL", as.Date("2023-09-30"), NA, NA, NA,
  "MSFT", as.Date("2023-12-31"), 200, 150, 50,
  "MSFT", as.Date("2023-09-30"), NA, NA, NA,
  "GOOGL", as.Date("2023-12-31"), 150, 120, 30
)

test_that("function removes rows where all financial columns are NA", {
  financial_cols <- c("revenue", "expenses", "profit")
  actual <- identify_all_na_rows(test_df, financial_cols, "test statement")
  expected <- test_df %>% 
    dplyr::filter(!is.na(revenue) | !is.na(expenses) | !is.na(profit))
  expect_equal(actual, expected)
})

test_that("function returns original data when no rows have all NA financial columns", {
  clean_df <- test_df %>% 
    dplyr::mutate(revenue = dplyr::coalesce(revenue, 0))
  financial_cols <- c("revenue", "expenses", "profit")
  actual <- identify_all_na_rows(clean_df, financial_cols, "test statement")
  expected <- clean_df
  expect_equal(actual, expected)
})

test_that("function removes all rows when all have NA financial columns", {
  all_na_df <- test_df %>% 
    dplyr::mutate(revenue = NA, expenses = NA, profit = NA)
  financial_cols <- c("revenue", "expenses", "profit")
  actual <- identify_all_na_rows(all_na_df, financial_cols, "test statement")
  expected <- all_na_df[0, ]
  expect_equal(actual, expected)
})

test_that("function returns original data when financial_cols is empty", {
  financial_cols <- character(0)
  expect_output(
    actual <- identify_all_na_rows(test_df, financial_cols, "test statement"),
    "Warning: No financial columns found for test statement"
  )
  expect_equal(actual, test_df)
})

test_that("function works with data missing ticker and fiscalDateEnding columns", {
  minimal_df <- tibble::tribble(
    ~revenue, ~expenses, ~profit,
    100, 80, 20,
    NA, NA, NA,
    200, 150, 50
  )
  financial_cols <- c("revenue", "expenses", "profit")
  actual <- identify_all_na_rows(minimal_df, financial_cols, "test statement")
  expected <- minimal_df %>% 
    dplyr::filter(!is.na(revenue) | !is.na(expenses) | !is.na(profit))
  expect_equal(actual, expected)
})


test_that("function stops when financial_cols is not a character vector", {
  expect_error(
    identify_all_na_rows(test_df, 123, "test statement"),
    "^'financial_cols' must be a character vector, got: numeric$"
  )
})

test_that("function stops when statement_type is not a single character string", {
  financial_cols <- c("revenue", "expenses", "profit")
  expect_error(
    identify_all_na_rows(test_df, financial_cols, c("test", "statement")),
    "^'statement_type' must be a single character string, got: character of length 2$"
  )
})

test_that("function stops when statement_type is not character", {
  financial_cols <- c("revenue", "expenses", "profit")
  expect_error(
    identify_all_na_rows(test_df, financial_cols, 123),
    "^'statement_type' must be a single character string, got: numeric of length 1$"
  )
})
