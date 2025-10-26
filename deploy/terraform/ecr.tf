# ECR Repository for Docker images

resource "aws_ecr_repository" "avpipeline" {
  name                 = "avpipeline"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "avpipeline"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecr_lifecycle_policy" "avpipeline" {
  repository = aws_ecr_repository.avpipeline.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}
