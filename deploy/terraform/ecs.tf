# ECS Cluster

resource "aws_ecs_cluster" "avpipeline" {
  name = "avpipeline-cluster"

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

# ECS Task Definition

resource "aws_ecs_task_definition" "avpipeline" {
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
    Name        = "avpipeline-task"
    ManagedBy   = "terraform"
  }
}

# CloudWatch Log Group

resource "aws_cloudwatch_log_group" "avpipeline" {
  name              = "/ecs/avpipeline"
  retention_in_days = 7

  tags = {
    Name        = "avpipeline-logs"
    ManagedBy   = "terraform"
  }
}

# IAM Role for EventBridge to trigger ECS

resource "aws_iam_role" "eventbridge_ecs_role" {
  name = "avpipeline-eventbridge-ecs-role"

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
    Name        = "avpipeline-eventbridge-ecs-role"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "eventbridge_ecs_policy" {
  name = "avpipeline-eventbridge-ecs-policy"
  role = aws_iam_role.eventbridge_ecs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecs:RunTask"
      ]
      Resource = aws_ecs_task_definition.avpipeline.arn
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
    }]
  })
}

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

resource "aws_cloudwatch_event_target" "ecs_task" {
  rule      = aws_cloudwatch_event_rule.pipeline_schedule.name
  target_id = "avpipeline-ecs-task"
  arn       = aws_ecs_cluster.avpipeline.arn
  role_arn  = aws_iam_role.eventbridge_ecs_role.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.avpipeline.arn
    launch_type         = "FARGATE"
    platform_version    = "LATEST"

    network_configuration {
      subnets          = data.aws_subnets.default.ids
      assign_public_ip = true
    }
  }
}
