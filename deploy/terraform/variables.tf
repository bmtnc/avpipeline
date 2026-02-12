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
  description = "CPU units for Phase 1 ECS task (4096 = 4 vCPU for parallel S3 writes)"
  type        = number
  default     = 4096
}

variable "task_memory" {
  description = "Memory for Phase 1 ECS task in MB (8GB for parallel batch processing)"
  type        = number
  default     = 8192
}

variable "phase2_cpu" {
  description = "CPU units for Phase 2 ECS task (4096 = 4 vCPU for parallel processing)"
  type        = number
  default     = 4096
}

variable "phase2_memory" {
  description = "Memory for Phase 2 ECS task in MB (8GB for parallel ticker processing)"
  type        = number
  default     = 8192
}

variable "etf_symbol" {
  description = "ETF ticker symbol to fetch holdings from (e.g., IWV, QQQ, SPY)"
  type        = string
  default     = "IWV"
}

variable "start_date" {
  description = "Start date for historical data filtering (YYYY-MM-DD format)"
  type        = string
  default     = "2004-12-31"
}

variable "fetch_mode" {
  description = "Fetch mode for Phase 1 (full, price_only, quarterly_only)"
  type        = string
  default     = "full"
}

variable "phase2_mode" {
  description = "Phase 2 processing mode (incremental, full)"
  type        = string
  default     = "incremental"
}
