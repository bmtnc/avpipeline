#' Send Pipeline Notification
#'
#' Sends a notification via AWS SNS about pipeline execution status.
#'
#' @param topic_arn character: SNS topic ARN
#' @param subject character: Email subject line
#' @param message character: Email message body
#' @param region character: AWS region (default: "us-east-1")
#' @return logical: TRUE if notification sent successfully
#' @keywords internal
send_pipeline_notification <- function(
  topic_arn,
  subject,
  message,
  region = "us-east-1"
) {
  if (!is.character(topic_arn) || length(topic_arn) != 1) {
    stop(paste0(
      "send_pipeline_notification(): [topic_arn] must be a character scalar, not ",
      class(topic_arn)[1],
      " of length ",
      length(topic_arn)
    ))
  }

  if (!is.character(subject) || length(subject) != 1) {
    stop(paste0(
      "send_pipeline_notification(): [subject] must be a character scalar, not ",
      class(subject)[1],
      " of length ",
      length(subject)
    ))
  }

  if (!is.character(message) || length(message) != 1) {
    stop(paste0(
      "send_pipeline_notification(): [message] must be a character scalar, not ",
      class(message)[1],
      " of length ",
      length(message)
    ))
  }

  if (!is.character(region) || length(region) != 1) {
    stop(paste0(
      "send_pipeline_notification(): [region] must be a character scalar, not ",
      class(region)[1],
      " of length ",
      length(region)
    ))
  }

  result <- system2(
    "aws",
    args = c(
      "sns",
      "publish",
      "--topic-arn",
      topic_arn,
      "--subject",
      shQuote(subject),
      "--message",
      shQuote(message),
      "--region",
      region
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    stop(paste0(
      "send_pipeline_notification(): Failed to send SNS notification. Error: ",
      paste(result, collapse = "\n")
    ))
  }

  TRUE
}
