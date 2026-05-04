resource "aws_ecr_repository" "main" {
    for_each =  toset(var.repositories)
    name = "${var.project_name}-${var.environment}-${each.value}"
    image_tag_mutability = "IMMUTABLE"
    image_scanning_configuration {
     scan_on_push = true
    }

    tags ={
        Name = "${var.project_name}-${var.environment}-${each.value}"
        Environment = "${var.environment}"
        Project = "${var.project_name}"
    }
  
}

resource "aws_ecr_lifecycle_policy" "main" {
    for_each = toset(var.repositories)
    repository = aws_ecr_repository.main[each.value].name
    policy = jsonencode({
        rules = [
          {
          rulePriority = 1
          description = "Keep last ${var.image_retention_count} images"
          selection = {
            tagStatus = "any"
            countType = "imageCountMoreThan"
            countNumber = var.image_retention_count
          }
          action = {
            type = "expire"
          }

          }

        ]
    })
  
}