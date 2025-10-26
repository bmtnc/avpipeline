variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "email_address" {
  description = "Email address for SNS notifications"
  type        = string
}

variable "bucket_suffix" {
  description = "Suffix for S3 bucket name (bucket will be avpipeline-artifacts-{suffix})"
  type        = string
  default     = "prod"
}

variable "schedule_expression" {
  description = "EventBridge cron expression for pipeline execution"
  type        = string
  default     = "cron(0 6 ? * SUN *)"
}

variable "task_cpu" {
  description = "CPU units for ECS task (1024 = 1 vCPU)"
  type        = number
  default     = 2048
}

variable "task_memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 4096
}
