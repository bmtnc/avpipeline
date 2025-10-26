# Implementation Plan: AWS Deployment for Financial Data Pipeline

## Overview
Deploy the existing avpipeline financial data processing system to AWS for automated weekly execution with S3 artifact storage.

This implementation creates a containerized version of the existing TTM per-share financial artifact pipeline that runs on AWS ECS Fargate. The system will execute weekly, fetch data from Alpha Vantage API, process it through all pipeline stages, and upload the final parquet artifact to S3 with date-based versioning. Email notifications will be sent on success/failure, and S3 lifecycle policies will maintain only the most recent 4 weeks of artifacts (30-day retention).

The architecture leverages AWS managed services to minimize operational overhead: ECS Fargate for serverless compute, EventBridge for scheduling, Parameter Store for encrypted secrets, S3 for artifact storage, and SNS for notifications. All infrastructure will be defined in Terraform for reproducibility and version control.

## Types
Define configuration structures and S3 path patterns for AWS deployment.

**S3 Path Structure:**
- Bucket pattern: `financial-data-pipeline-[random-suffix]` (8-char random string for uniqueness)
- Artifact path: `ttm-artifacts/YYYY-MM-DD/ttm_per_share_financial_artifact.parquet`
- Example: `s3://financial-data-pipeline-a7x9k2m1/ttm-artifacts/2025-01-19/ttm_per_share_financial_artifact.parquet`

**AWS Parameter Store:**
- Key: `/avpipeline/alpha-vantage-api-key`
- Type: `SecureString` (encrypted with default AWS KMS key)

**SNS Topic:**
- Name: `financial-pipeline-notifications`
- Subscription: Email protocol to `barrymatanic@gmail.com`

**Container Configuration:**
- Memory: 4096 MB (4 GB)
- vCPU: 2
- Ephemeral storage: 30 GB (for cache directory)

**EventBridge Schedule:**
- Cron: `cron(0 6 ? * SUN *)` (Every Sunday at 6:00 AM UTC = 2:00 AM ET)

## Files
Detailed breakdown of new files to create and existing files to modify.

**New Files to Create:**

1. `Dockerfile` (project root)
   - Purpose: Container definition for R environment with all dependencies
   - Base: `rocker/r-ver:4.3.1` (official R Docker image)
   - Installs: System dependencies, R packages from DESCRIPTION, AWS CLI
   
2. `.dockerignore` (project root)
   - Purpose: Exclude unnecessary files from Docker build context
   - Excludes: cache/, renv/, tests/, .git/, plots/, output/

3. `scripts/run_pipeline_aws.R` (new AWS wrapper script)
   - Purpose: AWS-aware pipeline orchestration
   - Functions: Fetch API key from Parameter Store, run pipeline, upload to S3, send SNS notification
   
4. `R/upload_artifact_to_s3.R` (new package function)
   - Purpose: Upload parquet file to S3 with date-based key
   - Dependencies: AWS CLI (via system2)
   
5. `R/send_pipeline_notification.R` (new package function)
   - Purpose: Send SNS notification with pipeline status
   - Dependencies: AWS CLI (via system2() call)
   
6. `R/get_api_key_from_parameter_store.R` (new package function)
   - Purpose: Retrieve Alpha Vantage API key from AWS Parameter Store
   - Dependencies: AWS CLI (via system2() call)

7. `R/generate_s3_artifact_key.R` (new package function)
   - Purpose: Generate S3 key path with date-based versioning
   - Dependencies: None (base R only)

8. `deploy/terraform/main.tf` (Terraform root module)
   - Purpose: Main infrastructure orchestration
   - Resources: S3 bucket, SNS topic, EventBridge rule

9. `deploy/terraform/ecs.tf` (ECS resources)
   - Purpose: ECS cluster, task definition, execution role, task role
   - Resources: ECS cluster, task definition, IAM roles and policies

10. `deploy/terraform/ecr.tf` (ECR repository)
    - Purpose: Docker image repository
    - Resources: ECR repository with lifecycle policy

11. `deploy/terraform/variables.tf` (Terraform variables)
    - Purpose: Configurable deployment parameters
    - Variables: region, email, bucket_suffix, schedule_expression

12. `deploy/terraform/outputs.tf` (Terraform outputs)
    - Purpose: Display important resource ARNs and URLs
    - Outputs: S3 bucket name, ECR repository URL, ECS cluster name

13. `deploy/setup.sh` (deployment automation script)
    - Purpose: End-to-end deployment automation
    - Steps: Build Docker image, push to ECR, deploy Terraform, confirm SNS subscription

14. `deploy/README.md` (deployment documentation)
    - Purpose: Step-by-step manual deployment instructions
    - Sections: Prerequisites, AWS setup, Docker build, Terraform deployment, testing

15. `deploy/build_and_push.sh` (Docker build script)
    - Purpose: Build and push Docker image to ECR
    - Steps: Authenticate to ECR, build image, tag, push

**Existing Files to Modify:**

1. `DESCRIPTION`
   - Ensure `arrow` is in Imports section
   - Add note about AWS deployment capability in Description field

2. `.gitignore`
   - Add: `deploy/terraform/.terraform/`, `deploy/terraform/*.tfstate`, `deploy/terraform/*.tfstate.backup`, `deploy/terraform/.terraform.lock.hcl`

**Files NOT to Modify:**
- All existing R/ package functions
- All tests/
- `scripts/build_complete_ttm_pipeline.R` (called as-is by wrapper)

## Functions
Detailed breakdown of new functions and their specifications.

**New R Functions:**

1. `upload_artifact_to_s3(local_path, bucket_name, s3_key)`
   - File: `R/upload_artifact_to_s3.R`
   - Parameters:
     - `local_path`: character, path to local parquet file
     - `bucket_name`: character, S3 bucket name
     - `s3_key`: character, S3 object key (e.g., "ttm-artifacts/2025-01-19/file.parquet")
   - Returns: character, S3 URI of uploaded file
   - Implementation: Uses AWS CLI via `system2()` for `aws s3 cp` command
   - Error handling: Checks return status, stops with descriptive error if upload fails
   - Input validation: File existence, non-empty strings, valid S3 key format

2. `send_pipeline_notification(sns_topic_arn, status, message, region = "us-east-1")`
   - File: `R/send_pipeline_notification.R`
   - Parameters:
     - `sns_topic_arn`: character, SNS topic ARN
     - `status`: character, "SUCCESS" or "FAILURE"
     - `message`: character, detailed message body
     - `region`: character, AWS region (default: "us-east-1")
   - Returns: NULL (side effect only)
   - Implementation: Uses AWS CLI via `system2()` for `aws sns publish` command
   - Subject line: "Financial Pipeline [status] - YYYY-MM-DD"
   - Input validation: Valid ARN format, status in allowed values

3. `get_api_key_from_parameter_store(parameter_name, region = "us-east-1")`
   - File: `R/get_api_key_from_parameter_store.R`
   - Parameters:
     - `parameter_name`: character, Parameter Store key path
     - `region`: character, AWS region (default: "us-east-1")
   - Returns: character, decrypted parameter value
   - Implementation: Uses AWS CLI via `system2()` for `aws ssm get-parameter --with-decryption`
   - Error handling: Checks return status, stops if parameter doesn't exist
   - Input validation: Non-empty parameter name, valid path format

4. `generate_s3_artifact_key(base_path = "ttm-artifacts", date = Sys.Date())`
   - File: `R/generate_s3_artifact_key.R`
   - Parameters:
     - `base_path`: character, S3 prefix (default: "ttm-artifacts")
     - `date`: Date, date for versioning (default: today)
   - Returns: character, full S3 key path
   - Implementation: Formats date as YYYY-MM-DD, constructs path
   - Example output: "ttm-artifacts/2025-01-19/ttm_per_share_financial_artifact.parquet"

**Modified R Functions:**
- None (new functions only)

**New Bash Functions (in deploy/setup.sh):**

1. `check_prerequisites()` - Verify Docker, AWS CLI, Terraform installed
2. `create_random_suffix()` - Generate 8-character random string for bucket name
3. `build_docker_image()` - Build Docker image with tag
4. `push_to_ecr()` - Authenticate and push to ECR
5. `deploy_infrastructure()` - Run terraform init/plan/apply
6. `store_api_key()` - Prompt for and store API key in Parameter Store
7. `confirm_sns_subscription()` - Remind user to confirm email subscription

## Classes
No classes required for this R implementation (functional programming approach).

All functionality implemented as standalone functions following existing avpipeline package conventions.

## Dependencies
Detailed breakdown of new dependencies and configuration requirements.

**Docker Base Image:**
- `rocker/r-ver:4.3.1` (official R Docker images from Rocker Project)
- Includes R 4.3.1 and system build tools

**System Dependencies (installed in Dockerfile):**
- `awscli` - AWS Command Line Interface for S3/SNS/Parameter Store operations
- `libcurl4-openssl-dev` - Required for httr package
- `libssl-dev` - Required for httr package
- `libxml2-dev` - Required for XML parsing
- `libfontconfig1-dev` - Required for ggplot2
- `libharfbuzz-dev` - Required for ggplot2 text rendering
- `libfribidi-dev` - Required for ggplot2 text rendering
- `libjpeg-dev` - Required for image output
- `libpng-dev` - Required for image output

**R Package Dependencies (from DESCRIPTION):**
- All existing packages: magrittr, dplyr, httr, jsonlite, rlang, tibble, quadprog, roll, slider, devtools, ggplot2, tidyr, lubridate, stringr, zoo
- `arrow` - Must be in Imports section
- Note: No new R packages required (using AWS CLI instead of R AWS packages for simplicity)

**AWS Services:**
- **ECS Fargate** - Serverless container execution
- **ECR** - Docker image registry
- **S3** - Artifact storage with lifecycle policies
- **Parameter Store** - Encrypted API key storage (AWS Systems Manager)
- **SNS** - Email notifications
- **EventBridge** - Scheduled execution
- **CloudWatch Logs** - Container logging (automatic)
- **IAM** - Roles and policies for ECS tasks

**Terraform Providers:**
- `hashicorp/aws` ~> 5.0 (AWS provider)
- `hashicorp/random` ~> 3.0 (for bucket suffix generation)

**Local Development Tools (for deployment):**
- Docker Desktop (or Docker Engine)
- AWS CLI v2
- Terraform >= 1.5.0
- Git (for version control)

**AWS IAM Permissions Required (for deployment user):**
- ECR: CreateRepository, PutImage, DescribeRepositories
- ECS: CreateCluster, RegisterTaskDefinition, CreateService
- S3: CreateBucket, PutBucketPolicy, PutLifecycleConfiguration
- SNS: CreateTopic, Subscribe
- EventBridge: PutRule, PutTargets
- IAM: CreateRole, AttachRolePolicy, PassRole
- SSM: PutParameter (for storing API key)
- CloudWatch: CreateLogGroup

## Testing
Testing strategy for local validation and AWS deployment verification.

**Local Docker Testing:**

1. Build Docker image locally:
   ```bash
   docker build -t avpipeline-local .
   ```

2. Test container with environment variables (before AWS deployment):
   ```bash
   docker run --rm \
     -e ALPHA_VANTAGE_API_KEY="your-key-here" \
     -e AWS_ACCESS_KEY_ID="test" \
     -e AWS_SECRET_ACCESS_KEY="test" \
     -e AWS_REGION="us-east-1" \
     avpipeline-local
   ```

3. Verify output:
   - Check console logs for pipeline progress messages
   - Verify final artifact creation message
   - Check for error messages or warnings

**AWS Deployment Testing:**

1. Manual ECS task execution (before EventBridge schedule):
   ```bash
   aws ecs run-task \
     --cluster financial-data-cluster \
     --task-definition avpipeline-task \
     --launch-type FARGATE \
     --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"
   ```

2. Monitor CloudWatch Logs:
   - Log group: `/ecs/avpipeline-task`
   - Check for pipeline stage messages
   - Verify API calls, data processing, S3 upload

3. Verify S3 artifact:
   ```bash
   aws s3 ls s3://financial-data-pipeline-[suffix]/ttm-artifacts/ --recursive
   ```

4. Check SNS notification email

5. Verify lifecycle policy:
   ```bash
   aws s3api get-bucket-lifecycle-configuration \
     --bucket financial-data-pipeline-[suffix]
   ```

**Testing Checklist:**
- [ ] Docker image builds successfully
- [ ] Container runs locally with test environment variables
- [ ] Pipeline completes all 5 stages without errors
- [ ] ECS task definition is valid
- [ ] ECS task can be manually triggered
- [ ] CloudWatch logs capture pipeline output
- [ ] Artifact appears in S3 with correct date-based key
- [ ] SNS email notification received with correct status
- [ ] EventBridge rule triggers task on schedule
- [ ] S3 lifecycle policy deletes old artifacts after 30 days
- [ ] Parameter Store retrieval works in container
- [ ] IAM roles have correct permissions (no access denied errors)

## Implementation Order
Sequential implementation steps to minimize conflicts and ensure successful integration.

**Phase 1: Docker Environment Setup**

1. Create `.dockerignore` file
2. Create `Dockerfile`
3. Test Docker build locally

**Phase 2: AWS Integration Functions**

4. Create `R/generate_s3_artifact_key.R`
5. Create `R/get_api_key_from_parameter_store.R`
6. Create `R/upload_artifact_to_s3.R`
7. Create `R/send_pipeline_notification.R`
8. Update DESCRIPTION file
9. Run `devtools::document()` to update documentation

**Phase 3: AWS Pipeline Wrapper**

10. Create `scripts/run_pipeline_aws.R`
11. Test wrapper script locally (with environment variables)

**Phase 4: Terraform Infrastructure**

12. Create `deploy/terraform/variables.tf`
13. Create `deploy/terraform/ecr.tf`
14. Create `deploy/terraform/ecs.tf`
15. Create `deploy/terraform/main.tf`
16. Create `deploy/terraform/outputs.tf`

**Phase 5: Deployment Automation**

17. Create `deploy/build_and_push.sh`
18. Create `deploy/setup.sh`
19. Create `deploy/README.md`

**Phase 6: Version Control and Documentation**

20. Update `.gitignore`
21. Update main README.md with AWS deployment section

**Phase 7: Testing and Validation**

22. Test local Docker build
23. Run deployment script
24. Confirm SNS subscription
25. Trigger manual ECS task execution
26. Verify S3 artifact
27. Wait for scheduled execution (or modify cron to test sooner)

**Phase 8: Cleanup and Documentation**

28. Document any AWS-specific learnings
29. Commit all changes to Git
30. Tag release version (e.g., v1.0.0-aws)

**Rollback Plan:**
If issues arise:
1. `cd deploy/terraform && terraform destroy` - Removes all AWS resources
2. Delete ECR images if desired
3. Remove Parameter Store key manually if desired
