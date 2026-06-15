locals {
  keep_latest_5_images_rule = [
    {
      rulePriority = 1
      description  = "Keep only the ${var.count_number} most recent images"
      selection = {
        tagStatus   = var.tag_status
        countType   = var.count_type
        countNumber = var.count_number
      }
      action = {
        type = "expire"
      }
    }
  ]
}

resource "aws_ecr_repository" "container_repo" {
  name                 = "${var.name}"
  image_tag_mutability = var.mutability
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name        = var.name
    FullName    = "${var.name}"
  })
}

resource "aws_ecr_lifecycle_policy" "cleanup_old_images" {
  repository = aws_ecr_repository.container_repo.name

  policy = jsonencode({
    rules = local.keep_latest_5_images_rule
  })
}