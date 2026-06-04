# GitHub Actions OIDC -> AWS
#
# Lets this repo's deploy workflow assume an IAM role to push Docker images to
# ECR, using a short-lived OIDC token instead of long-lived access keys stored
# in GitHub. Trust is scoped to pushes on `main` of this repo only.

variable "github_repository" {
  description = "GitHub repo (owner/name) whose Actions may assume the deploy role"
  type        = string
  default     = "bmtnc/avpipeline"
}

# OIDC identity provider for GitHub Actions. One per AWS account; if you already
# have a provider for token.actions.githubusercontent.com, import it instead of
# creating a second (AWS rejects duplicate provider URLs).
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name      = "github-actions-oidc"
    ManagedBy = "terraform"
  }
}

# Role the deploy workflow assumes. The `sub` condition pins trust to the main
# branch of this repo, so PR branches and forks cannot push images.
resource "aws_iam_role" "github_deploy" {
  name = "avpipeline-github-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:ref:refs/heads/main"
        }
      }
    }]
  })

  tags = {
    Name      = "avpipeline-github-deploy"
    ManagedBy = "terraform"
  }
}

# Least-privilege ECR push. GetAuthorizationToken must be account-wide ("*");
# the layer/image actions are scoped to the avpipeline repository.
resource "aws_iam_role_policy" "github_deploy_ecr" {
  name = "avpipeline-github-deploy-ecr"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = aws_ecr_repository.avpipeline.arn
      }
    ]
  })
}
