#!/bin/bash

# Build and Push Docker Image to ECR
# This script builds the Docker image and pushes it to AWS ECR

set -e

echo "=== Building and Pushing Docker Image to ECR ==="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is not running"
    exit 1
fi

# Get AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REPOSITORY="avpipeline"
IMAGE_TAG=${IMAGE_TAG:-latest}

echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
echo "ECR Repository: $ECR_REPOSITORY"
echo "Image Tag: $IMAGE_TAG"

# Login to ECR
echo ""
echo "[1/3] Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build Docker image
echo ""
echo "[2/3] Building Docker image..."
docker build --platform linux/amd64 -t $ECR_REPOSITORY:$IMAGE_TAG .

# Tag image for ECR
ECR_IMAGE_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG"
docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_IMAGE_URI

# Push image to ECR
echo ""
echo "[3/3] Pushing image to ECR..."
docker push $ECR_IMAGE_URI

echo ""
echo "=== Image Successfully Pushed ==="
echo "Image URI: $ECR_IMAGE_URI"
