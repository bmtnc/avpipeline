# AWS Deployment Guide

This directory contains all necessary files for deploying the avpipeline financial data processing system to AWS.

## Architecture Overview

The deployment uses:
- **ECS Fargate**: Serverless container execution
- **ECR**: Docker image storage
- **S3**: Artifact storage with 30-day lifecycle
- **Parameter Store**: Secure API key storage
- **SNS**: Email notifications
- **EventBridge**: Weekly scheduling (Sundays at 2am ET)
- **CloudWatch Logs**: Execution logging

## Prerequisites

Before deploying, ensure you have:

1. **AWS CLI** (v2 or later)
   ```bash
   aws --version
   ```

2. **Docker** (running)
   ```bash
   docker info
   ```

3. **Terraform** (v1.0 or later)
   ```bash
   terraform version
   ```

4. **AWS Credentials** configured
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Access Key, and Region (us-east-1)
   ```

5. **Alpha Vantage API Key**
   - Get a free API key at: https://www.alphavantage.co/support/#api-key

## Automated Deployment

The easiest way to deploy is using the automated setup script:

```bash
# From the project root directory
bash deploy/setup.sh
```

This script will:
1. Check prerequisites
2. Verify AWS credentials
3. Collect your email and API key
4. Store API key in Parameter Store
5. Deploy infrastructure with Terraform
6. Build and push Docker image
7. Prompt you to confirm SNS email subscription

**Important**: You will receive an email to confirm the SNS subscription. You must confirm it to receive pipeline notifications.

## Manual Deployment

If you prefer step-by-step deployment:

### Step 1: Store API Key

```bash
aws ssm put-parameter \
    --name "/avpipeline/alpha-vantage-api-key" \
    --type "SecureString" \
    --value "YOUR_API_KEY" \
    --region us-east-1
```

### Step 2: Deploy Infrastructure

```bash
cd deploy/terraform

# Initialize Terraform
terraform init

# Review planned changes
terraform plan -var="email_address=your@email.com"

# Apply changes
terraform apply -var="email_address=your@email.com"
```

### Step 3: Build and Push Docker Image

```bash
# From project root
bash deploy/build_and_push.sh
```

### Step 4: Confirm SNS Subscription

Check your email and click the confirmation link.

## Testing the Deployment

### View Logs

```bash
aws logs tail /ecs/avpipeline --follow --region us-east-1
```

### Manual Task Execution

Test the pipeline before the scheduled run:

```bash
# Get subnet IDs from your default VPC
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=default-for-az,Values=true" --query "Subnets[0].SubnetId" --output text --region us-east-1)

# Run task manually
aws ecs run-task \
    --cluster avpipeline-cluster \
    --task-definition avpipeline \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],assignPublicIp=ENABLED}" \
    --region us-east-1
```

### Check S3 Artifacts

```bash
# List artifacts
aws s3 ls s3://avpipeline-artifacts-prod/ttm-artifacts/ --recursive --region us-east-1

# Download latest artifact
aws s3 cp s3://avpipeline-artifacts-prod/ttm-artifacts/$(date +%Y-%m-%d)/ttm_per_share_financial_artifact.parquet . --region us-east-1
```

## Configuration

### Modify Schedule

Edit `deploy/terraform/variables.tf`:

```hcl
variable "schedule_expression" {
  default = "cron(0 6 ? * SUN *)"  # Sunday 2am ET = 6am UTC
}
```

Common cron patterns:
- Daily at 2am ET: `cron(0 6 ? * * *)`
- Monday-Friday at 2am ET: `cron(0 6 ? * MON-FRI *)`
- First day of month: `cron(0 6 1 * ? *)`

After changing, reapply Terraform:
```bash
cd deploy/terraform
terraform apply -var="email_address=your@email.com"
```

### Adjust Resources

Edit `deploy/terraform/variables.tf`:

```hcl
variable "task_cpu" {
  default = 2048  # 2 vCPU
}

variable "task_memory" {
  default = 4096  # 4 GB
}
```

## Monitoring

### CloudWatch Logs

View logs in AWS Console:
1. Go to CloudWatch → Log groups
2. Select `/ecs/avpipeline`
3. View log streams

### S3 Bucket

Monitor artifact creation:
1. Go to S3 → `avpipeline-artifacts-prod`
2. Navigate to `ttm-artifacts/YYYY-MM-DD/`

### Email Notifications

You'll receive emails for:
- Pipeline success (with execution time and S3 location)
- Pipeline failures (with error details)

## Updating the Pipeline

When you make code changes:

```bash
# Rebuild and push Docker image
bash deploy/build_and_push.sh

# The next scheduled run will use the new image
# Or trigger manually for immediate testing
```

## Cost Estimate

Approximate monthly costs for weekly execution:

- **ECS Fargate**: ~$2-3 (30 min @ 2 vCPU, 4GB, 4 runs)
- **S3 Storage**: ~$0.50 (4 artifacts @ ~100MB each)
- **ECR Storage**: ~$0.10 (1-2 images)
- **Other Services**: <$0.50 (SNS, Parameter Store, CloudWatch Logs)

**Total**: $3-6/month

## Troubleshooting

### Task Fails Immediately

Check CloudWatch Logs for error details:
```bash
aws logs tail /ecs/avpipeline --since 1h --region us-east-1
```

Common issues:
- **API key not found**: Verify Parameter Store has the key
- **Network timeout**: Check VPC/subnet configuration
- **Memory issues**: Increase `task_memory` in variables.tf

### No Email Notifications

1. Confirm SNS subscription in your email
2. Check SNS topic in AWS Console
3. Verify email address in Terraform variables

### Docker Build Fails

```bash
# Test locally
docker build -t avpipeline:test .

# Check for missing dependencies in Dockerfile
```

## Cleanup

To destroy all AWS resources:

```bash
cd deploy/terraform
terraform destroy -var="email_address=your@email.com"

# Manually delete Parameter Store entry
aws ssm delete-parameter --name "/avpipeline/alpha-vantage-api-key" --region us-east-1
```

## Support

For issues or questions:
1. Check CloudWatch Logs for error messages
2. Review Terraform outputs: `terraform output`
3. Verify AWS permissions for ECS, S3, SNS, ECR, SSM
