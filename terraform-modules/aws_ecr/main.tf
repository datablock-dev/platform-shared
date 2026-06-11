locals {
  keep_latest_5_images_rule = [
    {
      rulePriority = 1
      description  = "Keep only the 5 most recent images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }
  ]
}

resource "aws_ecr_repository" "container_repo" {
  name                 = "${var.name}-${terraform.workspace}"
  #provider             = aws.euwest1
  image_tag_mutability = var.mutability
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name        = var.name
    FullName    = "${var.name}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  })
}

resource "aws_ecr_lifecycle_policy" "cleanup_old_images" {
  repository = aws_ecr_repository.container_repo.name

  policy = jsonencode({
    rules = local.keep_latest_5_images_rule
  })
}