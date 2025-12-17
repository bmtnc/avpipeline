# Terraform outputs

output "ecr_repository_url" {
  description = "ECR repository URL for Docker images"
  value       = aws_ecr_repository.avpipeline.repository_url
}

output "s3_bucket_name" {
  description = "S3 bucket name for artifacts"
  value       = aws_s3_bucket.artifacts.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.artifacts.arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.avpipeline.name
}

output "ecs_task_definition_phase1_arn" {
  description = "ECS task definition ARN for Phase 1"
  value       = aws_ecs_task_definition.phase1.arn
}

output "ecs_task_definition_phase2_arn" {
  description = "ECS task definition ARN for Phase 2"
  value       = aws_ecs_task_definition.phase2.arn
}

output "ecs_task_definition_full_arn" {
  description = "ECS task definition ARN for full pipeline"
  value       = aws_ecs_task_definition.full.arn
}

output "step_functions_arn" {
  description = "Step Functions state machine ARN"
  value       = aws_sfn_state_machine.pipeline.arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  value       = aws_sns_topic.pipeline_notifications.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.avpipeline.name
}

output "eventbridge_rule_name" {
  description = "EventBridge schedule rule name"
  value       = aws_cloudwatch_event_rule.pipeline_schedule.name
}
