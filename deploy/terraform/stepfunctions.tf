# Step Functions State Machine for Pipeline Orchestration

# CloudWatch Log Group for Step Functions execution logs
resource "aws_cloudwatch_log_group" "sfn_logs" {
  name              = "/aws/states/avpipeline-orchestrator"
  retention_in_days = 30

  tags = {
    Name      = "avpipeline-stepfunctions-logs"
    ManagedBy = "terraform"
  }
}

# Resource policy to allow Step Functions to write to the log group
resource "aws_cloudwatch_log_resource_policy" "sfn_logs_policy" {
  policy_name = "avpipeline-stepfunctions-logs-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.sfn_logs.arn}:*"
    }]
  })
}

# IAM Role for Step Functions
resource "aws_iam_role" "sfn_role" {
  name = "avpipeline-stepfunctions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })

  tags = {
    Name      = "avpipeline-stepfunctions-role"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy" "sfn_policy" {
  name = "avpipeline-stepfunctions-policy"
  role = aws_iam_role.sfn_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask"
        ]
        Resource = [
          aws_ecs_task_definition.phase1.arn,
          aws_ecs_task_definition.phase2.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:StopTask",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "ecs:cluster" = aws_ecs_cluster.avpipeline.arn
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task_execution_role.arn,
          aws_iam_role.ecs_task_role.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "pipeline" {
  name     = "avpipeline-orchestrator"
  role_arn = aws_iam_role.sfn_role.arn

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn_logs.arn}:*"
    level                  = "ERROR"
    include_execution_data = true
  }

  definition = jsonencode({
    Comment = "AV Pipeline: Phase 1 (Fetch) -> Phase 2 (Generate)"
    StartAt = "Phase1Fetch"
    States = {
      Phase1Fetch = {
        Type           = "Task"
        Resource       = "arn:aws:states:::ecs:runTask.sync"
        TimeoutSeconds = 28800  # 8 hours - buffer for large ETFs (IWV ~2500 tickers)
        Parameters = {
          LaunchType     = "FARGATE"
          Cluster        = aws_ecs_cluster.avpipeline.arn
          TaskDefinition = aws_ecs_task_definition.phase1.arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = data.aws_subnets.default.ids
              AssignPublicIp = "ENABLED"
            }
          }
        }
        ResultPath = "$.phase1Result"
        Next       = "Phase2Generate"
        Retry = [{
          ErrorEquals     = ["States.Timeout", "States.TaskFailed"]
          IntervalSeconds = 60
          MaxAttempts     = 2
          BackoffRate     = 2.0
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "PipelineFailed"
          ResultPath  = "$.error"
        }]
      }
      Phase2Generate = {
        Type           = "Task"
        Resource       = "arn:aws:states:::ecs:runTask.sync"
        TimeoutSeconds = 28800  # 8 hours - buffer for large ETFs (IWV ~2500 tickers)
        Parameters = {
          LaunchType     = "FARGATE"
          Cluster        = aws_ecs_cluster.avpipeline.arn
          TaskDefinition = aws_ecs_task_definition.phase2.arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = data.aws_subnets.default.ids
              AssignPublicIp = "ENABLED"
            }
          }
        }
        ResultPath = "$.phase2Result"
        End        = true
        Retry = [{
          ErrorEquals     = ["States.Timeout", "States.TaskFailed"]
          IntervalSeconds = 60
          MaxAttempts     = 2
          BackoffRate     = 2.0
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "PipelineFailed"
          ResultPath  = "$.error"
        }]
      }
      PipelineFailed = {
        Type  = "Fail"
        Error = "PipelineExecutionFailed"
        Cause = "One of the pipeline phases failed. Check CloudWatch logs for details."
      }
    }
  })

  tags = {
    Name      = "avpipeline-orchestrator"
    ManagedBy = "terraform"
  }
}

# IAM Role for EventBridge to trigger Step Functions
resource "aws_iam_role" "eventbridge_sfn_role" {
  name = "avpipeline-eventbridge-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })

  tags = {
    Name      = "avpipeline-eventbridge-sfn-role"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy" "eventbridge_sfn_policy" {
  name = "avpipeline-eventbridge-sfn-policy"
  role = aws_iam_role.eventbridge_sfn_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "states:StartExecution"
      Resource = aws_sfn_state_machine.pipeline.arn
    }]
  })
}
