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

### Configure Pipeline Parameters

You can customize the ETF symbol and date range without rebuilding the Docker image. Edit `deploy/terraform/variables.tf`:

```hcl
variable "etf_symbol" {
  default = "QQQ"  # Change to IWB, SPY, etc.
}

variable "start_date" {
  default = "2004-12-31"  # Change to limit historical data
}
```

**Example: Switch to Russell 3000 (IWB)**
```bash
cd deploy/terraform
terraform apply -var="email_address=your@email.com" -var="etf_symbol=IWB"
```

**Example: Process only recent data (since 2020)**
```bash
terraform apply -var="email_address=your@email.com" -var="start_date=2020-01-01"
```

These changes only require redeploying the infrastructure (no Docker rebuild needed).

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

## Comprehensive Troubleshooting Guide: renv + Docker

This section documents the complete troubleshooting journey for deploying an R package with renv-managed dependencies in Docker/AWS. Understanding this process is critical for debugging similar issues.

### Overview: The Problem

The pipeline worked perfectly locally but failed in AWS ECS with the error:
```
Error in loadNamespace(x) : there is no package called 'devtools'
Execution halted
```

This occurred despite:
- All 120 packages being successfully installed during Docker build (confirmed locally)
- Docker image being 3.11GB (indicating packages were present)
- Local testing showing `devtools` was in the image at `/app/renv/library/`

### Part 1: System Dependencies (Build-Time Issues)

#### Issue 1: Platform Architecture Mismatch
**Error**: `Manifest does not contain descriptor matching platform 'linux/amd64'`

**Root Cause**: Building on ARM Mac (M4 Pro) without specifying target platform for AWS ECS (x86_64)

**Solution**: Added platform flag to `build_and_push.sh`
```bash
docker build --platform linux/amd64 -t avpipeline:latest .
```

**Why it works**: Forces Docker to build for AWS's x86_64 architecture, not ARM

---

#### Issue 2: R Version Mismatch
**Error**: `This R is version 4.3.1, package 'MASS' requires R >= 4.4.0`

**Root Cause**: Dockerfile base image (`rocker/r-ver:4.3.1`) didn't match `renv.lock` (generated with R 4.4.2)

**Solution**: Updated Dockerfile
```dockerfile
FROM rocker/r-ver:4.4.2
```

**Why it works**: R package compatibility requires matching major.minor versions

---

#### Issue 3-5: Missing System Libraries
Packages that compile C/C++ code require system libraries to be installed before `renv::restore()`:

**httpuv** (package 51/120): 
- Error: `fatal error: zlib.h: No such file or directory`
- Solution: Added `zlib1g-dev`

**textshaping** (package 105/120):
- Error: `Package 'harfbuzz' not found`
- Solution: Added `libharfbuzz-dev libfribidi-dev`

**ragg** (package 106/120):
- Error: `Package 'libtiff-4' not found`
- Solution: Added `libpng-dev libtiff5-dev libjpeg-dev`

**Final System Dependencies**: See Dockerfile for complete list (~25 system libraries)

---

### Part 2: The renv Bootstrapping Issue (Runtime Issue)

This was the most challenging issue because **the symptoms were misleading**.

#### What We Thought Would Work

Our mental model:
1. Run `RUN R -e "renv::restore()"` in Dockerfile
2. Install all 120 packages to `/app/renv/library/` during build
3. Copy `renv.lock`, `.Rprofile`, and `renv/activate.R` to image
4. At runtime, R would automatically use pre-installed packages

**Why we thought this**: This is how renv works in development environments, and we could verify packages were in the image.

---

#### Why It Didn't Work

When the container started in AWS ECS, CloudWatch logs showed:
```
# Bootstrapping renv 1.1.4 ---------------------------------------------------
- Downloading renv ... OK
- Installing renv  ... OK
- One or more packages recorded in the lockfile are not installed.
- Use `renv::status()` for more details.
Error in loadNamespace(x) : there is no package called 'devtools'
```

**What was happening**:
1. Container starts → Rscript runs `/app/scripts/run_pipeline_aws.R`
2. R sources `.Rprofile` (standard R startup behavior)
3. `.Rprofile` runs `source("renv/activate.R")`
4. `renv/activate.R` checks if packages are properly set up
5. renv sees the library directory but **doesn't trust it's complete**
6. renv bootstraps a fresh environment (downloads + installs renv itself)
7. renv looks for packages in the fresh environment (not the pre-built one)
8. Script tries to load devtools → **fails because it's looking in the wrong place**

---

#### Why We Thought It Would Work (Our False Assumptions)

**Assumption 1**: "If packages are in the image, R will find them"
- **Reality**: R needs `.libPaths()` to tell it where to look. renv was resetting this path during bootstrapping.

**Assumption 2**: "renv::restore() during build = packages ready at runtime"
- **Reality**: renv distinguishes between "development setup" (expects to bootstrap) and "production deployment" (packages should be pre-installed). We were triggering the development path.

**Assumption 3**: "Docker caching was causing stale images"
- **Reality**: We spent hours rebuilding with `--no-cache`, but caching wasn't the issue. The packages were always in the image; renv just wasn't using them.

**Assumption 4**: "AWS task definition versioning was somehow caching old state"
- **Reality**: AWS task definitions are immutable. New revisions always reference the latest image digest. The issue was inside the container's runtime behavior.

---

#### What Was Actually Wrong

The core problem was **renv's autoloader behavior**:

1. **renv's default design**: In development, `.Rprofile` + `renv/activate.R` checks for package consistency and bootstraps if needed
2. **Our Docker image**: Had packages pre-installed but still had the development-mode activation files
3. **The mismatch**: renv's checks couldn't verify packages were complete (because it uses different logic for pre-installed vs. fresh installs), so it triggered bootstrapping
4. **The result**: Runtime bootstrapping downloaded renv fresh, used a different library path, and couldn't find pre-installed packages

The smoking gun in `renv/activate.R`:
```r
# figure out whether the autoloader is enabled
enabled <- local({
  # ... checks environment variables ...
  # enable by default
  TRUE
})

if (enabled) {
  # ... runs bootstrap process ...
}
```

By default, renv **always** runs its autoloader unless explicitly disabled.

---

#### The Solution

We needed to tell renv: "Packages are pre-installed. Don't bootstrap. Use what's there."

**Change 1**: Disable renv autoloader in Dockerfile
```dockerfile
# Disable renv autoloader - use pre-installed packages from Docker build
ENV RENV_CONFIG_AUTOLOADER_ENABLED=FALSE
```

**Change 2**: Explicitly set library path in `scripts/run_pipeline_aws.R`
```r
#!/usr/bin/env Rscript

# Use pre-built renv library installed during Docker build
.libPaths(c("/app/renv/library/linux-ubuntu-noble/R-4.4/x86_64-pc-linux-gnu", .libPaths()))

# Load package functions
devtools::load_all("/app")
```

---

#### Why This Solution Works

1. **`RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`**:
   - Tells renv's `activate.R` to skip the autoloader checks
   - Prevents renv from bootstrapping at runtime
   - `.Rprofile` still runs but does nothing (autoloader disabled)

2. **`.libPaths()`**:
   - Explicitly tells R where packages are located
   - Prepends the pre-built library path to R's search path
   - Ensures `devtools::load_all()` and all package loads find the correct packages

3. **Docker build still uses renv**:
   - `RUN R -e "renv::restore()"` still installs packages from `renv.lock`
   - Ensures exact version reproducibility
   - Creates the library directory we reference at runtime

**The key insight**: In Docker, renv's role is at **build time** (install packages), not **runtime** (set up environment). Docker itself is the deployment/reproducibility mechanism.

---

### Verification: How We Knew It Worked

After the fix, CloudWatch logs showed:
```
ℹ Loading avpipeline
=== Starting AWS Pipeline Execution ===
AWS Region: us-east-1
S3 Bucket: avpipeline-artifacts-prod
[1/4] Retrieving API key from Parameter Store...
API key retrieved successfully
[2/4] Running TTM pipeline...
```

**Notice**:
- **NO** "Bootstrapping renv" message
- `devtools::load_all()` succeeded immediately
- Pipeline executed normally

---

### Key Lessons Learned

1. **renv in Docker requires explicit runtime configuration**
   - Development mode (local): `.Rprofile` + autoloader
   - Production mode (Docker): Disable autoloader + explicit `.libPaths()`

2. **Build-time success ≠ runtime success**
   - Packages can be in the image but not accessible if library paths aren't set correctly

3. **Docker caching was a red herring**
   - We repeatedly rebuilt with `--no-cache` thinking cache was the issue
   - The actual issue was renv's runtime behavior, not the build process

4. **AWS task definition versioning is correct**
   - Creating new revisions (`:1`, `:2`, `:3`, etc.) is normal AWS behavior
   - Each revision correctly referenced the latest image digest
   - The issue was never with AWS; it was inside the container

5. **Misleading error messages**
   - "Package not installed" when packages ARE installed just means R can't find them in its current search path

---

### Debug Strategy for Similar Issues

If you see "package not found" errors in ECS but packages are in the Docker image:

1. **Verify packages are in the image**:
   ```bash
   docker run -it avpipeline:latest ls /app/renv/library/*/R-*/
   ```

2. **Check CloudWatch logs for "Bootstrapping renv"**:
   - If present: renv is running its autoloader at runtime
   - Solution: Disable autoloader + set `.libPaths()`

3. **Test locally with --platform**:
   ```bash
   docker build --platform linux/amd64 -t avpipeline:test .
   docker run --platform linux/amd64 avpipeline:test
   ```

4. **Verify .libPaths() at runtime**:
   Add to script: `message(paste(.libPaths(), collapse="\n"))`

---

### Build Time Expectations

With all fixes in place:
- **Full build with --no-cache**: ~30 minutes
  - System dependencies: ~2 minutes
  - renv::restore() (120 packages): ~25 minutes
  - Layers (copy files, etc.): ~3 minutes

- **Incremental build** (code changes only): ~10 seconds
  - Docker reuses cached layers for dependencies
  - Only rebuilds changed code layers

---

### Future Considerations

If adding new R packages to `renv.lock`:

1. **Check for system dependencies**:
   - Does package compile C/C++? (has `src/` directory)
   - Read package documentation for required system libraries
   - Add to Dockerfile before `RUN R -e "renv::restore()"`

2. **Test with --no-cache**:
   ```bash
   docker build --no-cache --platform linux/amd64 -t avpipeline:test .
   ```

3. **Verify runtime behavior**:
   - Check CloudWatch logs for "Bootstrapping renv" (should NOT appear)
   - Confirm packages load correctly

4. **Update documentation**:
   - Document any new system dependencies
   - Note any package-specific runtime requirements

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
