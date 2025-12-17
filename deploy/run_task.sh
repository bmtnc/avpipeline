#!/bin/bash
# Run pipeline manually
#
# Usage:
#   ./run_task.sh                    # Run via Step Functions (recommended)
#   ./run_task.sh stepfunctions      # Same as above
#   ./run_task.sh phase1             # Run only Phase 1 (fetch)
#   ./run_task.sh phase2             # Run only Phase 2 (generate)
#   ./run_task.sh full               # Run as single task (legacy mode)
#
# Environment overrides (optional):
#   ETF_SYMBOL=SPY ./run_task.sh     # Override ETF
#   FETCH_MODE=price_only ./run_task.sh phase1  # Override fetch mode

set -e

MODE="${1:-stepfunctions}"
AWS_REGION="us-east-1"
CLUSTER_NAME="avpipeline-cluster"

echo "=== AV Pipeline Manual Run ==="
echo "Mode: $MODE"
echo ""

# Get terraform outputs
cd "$(dirname "$0")/terraform"

S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null)
SNS_TOPIC_ARN=$(terraform output -raw sns_topic_arn 2>/dev/null)
SFN_ARN=$(terraform output -raw step_functions_arn 2>/dev/null || echo "")
PHASE1_TASK_DEF=$(terraform output -raw ecs_task_definition_phase1_arn 2>/dev/null || echo "")
PHASE2_TASK_DEF=$(terraform output -raw ecs_task_definition_phase2_arn 2>/dev/null || echo "")
FULL_TASK_DEF=$(terraform output -raw ecs_task_definition_full_arn 2>/dev/null || echo "")

if [ -z "$S3_BUCKET" ]; then
    echo "Error: Could not get terraform outputs. Run 'terraform apply' first."
    exit 1
fi

echo "S3 Bucket: $S3_BUCKET"

# Get subnet for ECS tasks
get_subnet() {
    aws ec2 describe-subnets \
        --filters "Name=default-for-az,Values=true" \
        --query "Subnets[0].SubnetId" \
        --output text \
        --region "$AWS_REGION"
}

# Run ECS task with given task definition
run_ecs_task() {
    local TASK_DEF="$1"
    local PHASE_NAME="$2"

    SUBNET_ID=$(get_subnet)
    if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" = "None" ]; then
        echo "Error: Could not find default VPC subnet"
        exit 1
    fi

    echo "Using subnet: $SUBNET_ID"
    echo "Starting $PHASE_NAME task..."

    TASK_ARN=$(aws ecs run-task \
        --cluster "$CLUSTER_NAME" \
        --task-definition "$TASK_DEF" \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],assignPublicIp=ENABLED}" \
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
}

case "$MODE" in
    "stepfunctions"|"sfn"|"")
        if [ -z "$SFN_ARN" ]; then
            echo "Error: Step Functions not deployed. Run 'terraform apply' first."
            exit 1
        fi

        echo "Starting Step Functions execution..."
        echo "State Machine: $SFN_ARN"
        echo ""

        EXECUTION_ARN=$(aws stepfunctions start-execution \
            --state-machine-arn "$SFN_ARN" \
            --region "$AWS_REGION" \
            --query 'executionArn' \
            --output text)

        EXECUTION_NAME=$(echo "$EXECUTION_ARN" | awk -F':' '{print $NF}')

        echo "=== Step Functions Execution Started ==="
        echo "Execution ARN: $EXECUTION_ARN"
        echo ""
        echo "View execution:"
        echo "  https://${AWS_REGION}.console.aws.amazon.com/states/home?region=${AWS_REGION}#/executions/details/${EXECUTION_ARN}"
        echo ""
        echo "View logs:"
        echo "  aws logs tail /ecs/avpipeline --follow --region $AWS_REGION"
        echo ""
        echo "Check status:"
        echo "  aws stepfunctions describe-execution --execution-arn $EXECUTION_ARN --query 'status'"
        ;;

    "phase1")
        if [ -z "$PHASE1_TASK_DEF" ]; then
            echo "Error: Phase 1 task definition not found. Run 'terraform apply' first."
            exit 1
        fi
        run_ecs_task "$PHASE1_TASK_DEF" "Phase 1 (Fetch)"
        ;;

    "phase2")
        if [ -z "$PHASE2_TASK_DEF" ]; then
            echo "Error: Phase 2 task definition not found. Run 'terraform apply' first."
            exit 1
        fi
        run_ecs_task "$PHASE2_TASK_DEF" "Phase 2 (Generate)"
        ;;

    "full")
        if [ -z "$FULL_TASK_DEF" ]; then
            echo "Error: Full task definition not found. Run 'terraform apply' first."
            exit 1
        fi
        run_ecs_task "$FULL_TASK_DEF" "Full Pipeline"
        ;;

    *)
        echo "Error: Unknown mode '$MODE'"
        echo ""
        echo "Usage: ./run_task.sh [mode]"
        echo ""
        echo "Modes:"
        echo "  stepfunctions  Run via Step Functions (Phase 1 -> Phase 2)"
        echo "  phase1         Run only Phase 1 (fetch raw data)"
        echo "  phase2         Run only Phase 2 (generate artifacts)"
        echo "  full           Run as single task (legacy mode)"
        exit 1
        ;;
esac
