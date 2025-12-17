#!/bin/bash
# Run ECS task manually
#
# Usage:
#   ./run_task.sh              # Run with defaults (QQQ, full mode)
#   ./run_task.sh SPY          # Run for specific ETF
#   ./run_task.sh QQQ price_only   # Run with specific fetch mode

set -e

# Parse arguments
ETF_SYMBOL="${1:-QQQ}"
FETCH_MODE="${2:-full}"

AWS_REGION="us-east-1"
CLUSTER_NAME="avpipeline-cluster"
TASK_FAMILY="avpipeline"

echo "=== Running ECS Task ==="
echo "ETF: $ETF_SYMBOL"
echo "Fetch Mode: $FETCH_MODE"
echo ""

# Get terraform outputs
cd "$(dirname "$0")/terraform"

S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null | tr -d '"')
SNS_TOPIC_ARN=$(terraform output -raw sns_topic_arn 2>/dev/null)
TASK_DEF_ARN=$(terraform output -raw ecs_task_definition_arn 2>/dev/null)

if [ -z "$S3_BUCKET" ] || [ -z "$SNS_TOPIC_ARN" ]; then
    echo "Error: Could not get terraform outputs. Run 'terraform apply' first."
    exit 1
fi

echo "S3 Bucket: $S3_BUCKET"
echo "SNS Topic: $SNS_TOPIC_ARN"
echo ""

# Get first subnet from default VPC
SUBNET_ID=$(aws ec2 describe-subnets \
    --filters "Name=default-for-az,Values=true" \
    --query "Subnets[0].SubnetId" \
    --output text \
    --region "$AWS_REGION")

if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" = "None" ]; then
    echo "Error: Could not find default VPC subnet"
    exit 1
fi

echo "Using subnet: $SUBNET_ID"
echo ""

# Build environment overrides JSON
ENV_OVERRIDES=$(cat <<EOF
{
    "containerOverrides": [{
        "name": "avpipeline",
        "environment": [
            {"name": "ETF_SYMBOL", "value": "$ETF_SYMBOL"},
            {"name": "S3_BUCKET", "value": "$S3_BUCKET"},
            {"name": "SNS_TOPIC_ARN", "value": "$SNS_TOPIC_ARN"},
            {"name": "FETCH_MODE", "value": "$FETCH_MODE"}
        ]
    }]
}
EOF
)

# Run the task
echo "Starting ECS task..."
TASK_ARN=$(aws ecs run-task \
    --cluster "$CLUSTER_NAME" \
    --task-definition "$TASK_DEF_ARN" \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],assignPublicIp=ENABLED}" \
    --overrides "$ENV_OVERRIDES" \
    --region "$AWS_REGION" \
    --query 'tasks[0].taskArn' \
    --output text)

if [ -z "$TASK_ARN" ] || [ "$TASK_ARN" = "None" ]; then
    echo "Error: Failed to start task"
    exit 1
fi

TASK_ID=$(echo "$TASK_ARN" | awk -F'/' '{print $NF}')

echo ""
echo "=== Task Started ==="
echo "Task ARN: $TASK_ARN"
echo "Task ID:  $TASK_ID"
echo ""
echo "View logs:"
echo "  aws logs tail /ecs/avpipeline --follow --region $AWS_REGION"
echo ""
echo "Check status:"
echo "  aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ID --region $AWS_REGION --query 'tasks[0].lastStatus'"
