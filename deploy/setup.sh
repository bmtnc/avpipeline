#!/bin/bash

# Complete AWS Deployment Setup Script
# This script performs end-to-end deployment of the avpipeline to AWS

set -e

echo "=== AVPipeline AWS Deployment Setup ==="
echo ""

# Prerequisites check
echo "[Step 1/8] Checking prerequisites..."

if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed"
    exit 1
fi

echo "✓ All prerequisites installed"

# Check AWS credentials
echo ""
echo "[Step 2/8] Verifying AWS credentials..."
aws sts get-caller-identity > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: AWS credentials not configured"
    echo "Run: aws configure"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}
echo "✓ AWS credentials verified (Account: $AWS_ACCOUNT_ID, Region: $AWS_REGION)"

# Get user inputs
echo ""
echo "[Step 3/8] Collecting configuration..."

read -p "Enter your email address for notifications: " EMAIL_ADDRESS
if [ -z "$EMAIL_ADDRESS" ]; then
    echo "Error: Email address is required"
    exit 1
fi

read -p "Enter Alpha Vantage API key: " API_KEY
if [ -z "$API_KEY" ]; then
    echo "Error: API key is required"
    exit 1
fi

echo "✓ Configuration collected"

# Store API key in Parameter Store
echo ""
echo "[Step 4/8] Storing API key in Parameter Store..."
aws ssm put-parameter \
    --name "/avpipeline/alpha-vantage-api-key" \
    --type "SecureString" \
    --value "$API_KEY" \
    --overwrite \
    --region $AWS_REGION \
    > /dev/null

echo "✓ API key stored in Parameter Store"

# Initialize and apply Terraform
echo ""
echo "[Step 5/8] Deploying infrastructure with Terraform..."
cd deploy/terraform

terraform init
terraform apply \
    -var="email_address=$EMAIL_ADDRESS" \
    -var="aws_region=$AWS_REGION" \
    -auto-approve

ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url)
S3_BUCKET_NAME=$(terraform output -raw s3_bucket_name)
SNS_TOPIC_ARN=$(terraform output -raw sns_topic_arn)

cd ../..

echo "✓ Infrastructure deployed"

# Build and push Docker image
echo ""
echo "[Step 6/8] Building and pushing Docker image..."
cd /Users/barrymatanic/Documents/r/avpipeline
AWS_REGION=$AWS_REGION bash deploy/build_and_push.sh

echo "✓ Docker image pushed to ECR"

# Confirm SNS subscription
echo ""
echo "[Step 7/8] SNS Email Subscription"
echo "⚠️  IMPORTANT: Check your email ($EMAIL_ADDRESS) and confirm the SNS subscription"
read -p "Press Enter after confirming the subscription..."

# Test execution
echo ""
echo "[Step 8/8] Manual test execution..."
echo ""
echo "To manually test the pipeline:"
echo "1. Go to AWS Console → ECS → Clusters → avpipeline-cluster"
echo "2. Click on 'Tasks' tab → 'Run new task'"
echo "3. Or run: aws ecs run-task --cluster avpipeline-cluster --task-definition avpipeline --launch-type FARGATE --network-configuration \"awsvpcConfiguration={subnets=[YOUR_SUBNET_ID],assignPublicIp=ENABLED}\" --region $AWS_REGION"
echo ""
echo "To view logs:"
echo "  aws logs tail /ecs/avpipeline --follow --region $AWS_REGION"
echo ""

# Deployment summary
echo "=== Deployment Complete ==="
echo ""
echo "Resources created:"
echo "  - ECR Repository: $ECR_REPOSITORY_URL"
echo "  - S3 Bucket: $S3_BUCKET_NAME"
echo "  - SNS Topic: $SNS_TOPIC_ARN"
echo "  - ECS Cluster: avpipeline-cluster"
echo "  - EventBridge Schedule: Every Sunday at 2am ET"
echo ""
echo "Next steps:"
echo "  1. Confirm SNS email subscription"
echo "  2. Test manual ECS task execution"
echo "  3. Monitor CloudWatch Logs: /ecs/avpipeline"
echo "  4. Verify artifact in S3 after first run"
echo ""
