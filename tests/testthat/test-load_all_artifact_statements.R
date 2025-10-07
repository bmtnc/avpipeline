test_that("load_all_artifact_statements returns named list with all statements", {
  skip_if_not(file.exists("cache/earnings_artifact.csv"), "Cache files not available")
  
  result <- load_all_artifact_statements()
  
  expect_type(result, "list")
  expect_named(result, c("earnings", "cash_flow", "income_statement", "balance_sheet"))
  expect_s3_class(result$earnings, "data.frame")
  expect_s3_class(result$cash_flow, "data.frame")
  expect_s3_class(result$income_statement, "data.frame")
  expect_s3_class(result$balance_sheet, "data.frame")
})

test_that("load_all_artifact_statements validates files exist", {
  temp_dir <- tempdir()
  original_wd <- getwd()
  
  tryCatch({
    setwd(temp_dir)
    
    expect_error(
      load_all_artifact_statements(),
      "validate_artifact_files.*Missing required files"
    )
  }, finally = {
    setwd(original_wd)
  })
})
