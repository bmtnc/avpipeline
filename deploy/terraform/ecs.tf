# ECS Cluster

resource "aws_ecs_cluster" "avpipeline" {
  name = "avpipeline-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "avpipeline-cluster"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# IAM Role for ECS Task Execution (pulls images, writes logs)

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "avpipeline-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "avpipeline-ecs-task-execution-role"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task (application permissions)

resource "aws_iam_role" "ecs_task_role" {
  name = "avpipeline-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "avpipeline-ecs-task-role"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "avpipeline-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.artifacts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/avpipeline/alpha-vantage-api-key"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.pipeline_notifications.arn
      }
    ]
  })
}

# ECS Task Definition - Phase 1 (Fetch)

resource "aws_ecs_task_definition" "phase1" {
  family                   = "avpipeline-phase1"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "avpipeline"
    image     = "${aws_ecr_repository.avpipeline.repository_url}:latest"
    essential = true

    environment = [
      {
        name  = "PIPELINE_PHASE"
        value = "phase1"
      },
      {
        name  = "AWS_REGION"
        value = var.aws_region
      },
      {
        name  = "S3_BUCKET"
        value = aws_s3_bucket.artifacts.id
      },
      {
        name  = "SNS_TOPIC_ARN"
        value = aws_sns_topic.pipeline_notifications.arn
      },
      {
        name  = "ETF_SYMBOL"
        value = var.etf_symbol
      },
      {
        name  = "FETCH_MODE"
        value = var.fetch_mode
      },
      {
        name  = "START_DATE"
        value = var.start_date
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.avpipeline.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "phase1"
      }
    }
  }])

  tags = {
    Name      = "avpipeline-phase1-task"
    ManagedBy = "terraform"
  }
}

# ECS Task Definition - Phase 2 (Generate)

resource "aws_ecs_task_definition" "phase2" {
  family                   = "avpipeline-phase2"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.phase2_cpu
  memory                   = var.phase2_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "avpipeline"
    image     = "${aws_ecr_repository.avpipeline.repository_url}:latest"
    essential = true

    environment = [
      {
        name  = "PIPELINE_PHASE"
        value = "phase2"
      },
      {
        name  = "AWS_REGION"
        value = var.aws_region
      },
      {
        name  = "S3_BUCKET"
        value = aws_s3_bucket.artifacts.id
      },
      {
        name  = "SNS_TOPIC_ARN"
        value = aws_sns_topic.pipeline_notifications.arn
      },
      {
        name  = "ETF_SYMBOL"
        value = var.etf_symbol
      },
      {
        name  = "START_DATE"
        value = var.start_date
      },
      {
        name  = "PHASE2_MODE"
        value = var.phase2_mode
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.avpipeline.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "phase2"
      }
    }
  }])

  tags = {
    Name      = "avpipeline-phase2-task"
    ManagedBy = "terraform"
  }
}

# ECS Task Definition - Full Pipeline (for manual runs / backwards compatibility)

resource "aws_ecs_task_definition" "full" {
  family                   = "avpipeline"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "avpipeline"
    image     = "${aws_ecr_repository.avpipeline.repository_url}:latest"
    essential = true

    environment = [
      {
        name  = "PIPELINE_PHASE"
        value = "full"
      },
      {
        name  = "AWS_REGION"
        value = var.aws_region
      },
      {
        name  = "S3_BUCKET"
        value = aws_s3_bucket.artifacts.id
      },
      {
        name  = "SNS_TOPIC_ARN"
        value = aws_sns_topic.pipeline_notifications.arn
      },
      {
        name  = "ETF_SYMBOL"
        value = var.etf_symbol
      },
      {
        name  = "FETCH_MODE"
        value = var.fetch_mode
      },
      {
        name  = "START_DATE"
        value = var.start_date
      },
      {
        name  = "PHASE2_MODE"
        value = var.phase2_mode
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.avpipeline.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name      = "avpipeline-full-task"
    ManagedBy = "terraform"
  }
}

# CloudWatch Log Group

resource "aws_cloudwatch_log_group" "avpipeline" {
  name              = "/ecs/avpipeline"
  retention_in_days = 30

  tags = {
    Name        = "avpipeline-logs"
    ManagedBy   = "terraform"
  }
}

# Note: EventBridge IAM role for Step Functions is defined in stepfunctions.tf

# Get default VPC and subnets for ECS tasks

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# EventBridge Rule for scheduled execution

resource "aws_cloudwatch_event_rule" "pipeline_schedule" {
  name                = "avpipeline-schedule"
  description         = "Triggers avpipeline ECS task on schedule"
  schedule_expression = var.schedule_expression

  tags = {
    Name        = "avpipeline-schedule"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_event_target" "step_functions" {
  rule      = aws_cloudwatch_event_rule.pipeline_schedule.name
  target_id = "avpipeline-stepfunctions"
  arn       = aws_sfn_state_machine.pipeline.arn
  role_arn  = aws_iam_role.eventbridge_sfn_role.arn
}

# CloudWatch Alarms for Pipeline Monitoring

resource "aws_cloudwatch_metric_alarm" "pipeline_execution_failed" {
  alarm_name          = "avpipeline-execution-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Pipeline execution failed - check CloudWatch logs"
  alarm_actions       = [aws_sns_topic.pipeline_notifications.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.pipeline.arn
  }

  tags = {
    Name      = "avpipeline-execution-failed-alarm"
    ManagedBy = "terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "pipeline_execution_timed_out" {
  alarm_name          = "avpipeline-execution-timed-out"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsTimedOut"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Pipeline execution timed out - task may be stuck"
  alarm_actions       = [aws_sns_topic.pipeline_notifications.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.pipeline.arn
  }

  tags = {
    Name      = "avpipeline-execution-timed-out-alarm"
    ManagedBy = "terraform"
  }
}
