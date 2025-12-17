#' Get API Key from Parameter Store
#'
#' Retrieves the Alpha Vantage API key from AWS Systems Manager Parameter Store.
#'
#' @param parameter_name character: The parameter name in Parameter Store (default: "/avpipeline/alpha-vantage-api-key")
#' @param region character: AWS region (default: "us-east-1")
#' @return character: The API key value
#' @keywords internal
get_api_key_from_parameter_store <- function(
  parameter_name = "/avpipeline/alpha-vantage-api-key",
  region = "us-east-1"
) {
  validate_character_scalar(parameter_name, name = "parameter_name")
  validate_character_scalar(region, name = "region")

  cmd <- sprintf(
    "aws ssm get-parameter --name %s --with-decryption --region %s --query Parameter.Value --output text",
    shQuote(parameter_name),
    shQuote(region)
  )

  result <- system2_with_timeout(
    "aws",
    args = c(
      "ssm",
      "get-parameter",
      "--name",
      parameter_name,
      "--with-decryption",
      "--region",
      region,
      "--query",
      "Parameter.Value",
      "--output",
      "text"
    ),
    timeout_seconds = 30,
    stdout = TRUE,
    stderr = TRUE
  )

  if (is_timeout_result(result)) {
    stop("get_api_key_from_parameter_store(): Parameter Store request timed out after 30 seconds")
  }

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    stop(paste0(
      "get_api_key_from_parameter_store(): Failed to retrieve parameter from Parameter Store. Error: ",
      paste(result, collapse = "\n")
    ))
  }

  api_key <- trimws(paste(result, collapse = ""))

  if (nchar(api_key) == 0) {
    stop(
      "get_api_key_from_parameter_store(): Retrieved empty API key from Parameter Store"
    )
  }

  api_key
}
