test_that("validate_character_scalar succeeds with valid string", {
  expect_null(validate_character_scalar("test"))
  expect_null(validate_character_scalar(""))  # empty string allowed by default
})

test_that("validate_character_scalar rejects non-character types", {
  expect_error(
    validate_character_scalar(123),
    "Input must be a character scalar.*Received: numeric"
  )
  expect_error(
    validate_character_scalar(TRUE),
    "Input must be a character scalar.*Received: logical"
  )
  expect_error(
    validate_character_scalar(list("a")),
    "Input must be a character scalar.*Received: list"
  )
})

test_that("validate_character_scalar rejects vectors of length != 1", {
  expect_error(
    validate_character_scalar(c("a", "b")),
    "Input must be a character scalar.*length 2"
  )
  expect_error(
    validate_character_scalar(character(0)),
    "Input must be a character scalar.*length 0"
  )
})

test_that("validate_character_scalar enforces non-empty when allow_empty = FALSE", {
  expect_null(validate_character_scalar("test", allow_empty = FALSE))
  expect_error(
    validate_character_scalar("", allow_empty = FALSE),
    "must be a non-empty string"
  )
})

test_that("validate_character_scalar uses custom name in error messages", {
  expect_error(
    validate_character_scalar(123, name = "ticker"),
    "ticker must be a character scalar"
  )
})
