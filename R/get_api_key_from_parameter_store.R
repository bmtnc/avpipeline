#' Get API Key from Parameter Store
#'
#' Retrieves the Alpha Vantage API key from AWS Systems Manager Parameter Store.
#'
#' @param parameter_name character: The parameter name in Parameter Store (default: "/avpipeline/alpha-vantage-api-key")
#' @param region character: AWS region (default: "us-east-1")
#' @return character: The API key value
#' @keywords internal
get_api_key_from_parameter_store <- function(parameter_name = "/avpipeline/alpha-vantage-api-key",
                                             region = "us-east-1") {
  if (!is.character(parameter_name) || length(parameter_name) != 1) {
    stop(paste0("get_api_key_from_parameter_store(): [parameter_name] must be a character scalar, not ", 
                class(parameter_name)[1], " of length ", length(parameter_name)))
  }
  
  if (!is.character(region) || length(region) != 1) {
    stop(paste0("get_api_key_from_parameter_store(): [region] must be a character scalar, not ", 
                class(region)[1], " of length ", length(region)))
  }
  
  cmd <- sprintf("aws ssm get-parameter --name %s --with-decryption --region %s --query Parameter.Value --output text",
                 shQuote(parameter_name), shQuote(region))
  
  result <- system2("aws", 
                    args = c("ssm", "get-parameter", 
                            "--name", parameter_name,
                            "--with-decryption",
                            "--region", region,
                            "--query", "Parameter.Value",
                            "--output", "text"),
                    stdout = TRUE, 
                    stderr = TRUE)
  
  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    stop(paste0("get_api_key_from_parameter_store(): Failed to retrieve parameter from Parameter Store. Error: ", 
                paste(result, collapse = "\n")))
  }
  
  api_key <- trimws(paste(result, collapse = ""))
  
  if (nchar(api_key) == 0) {
    stop("get_api_key_from_parameter_store(): Retrieved empty API key from Parameter Store")
  }
  
  api_key
}
