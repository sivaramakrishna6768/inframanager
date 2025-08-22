########################################
# InfraManager - ECR
########################################

resource "aws_ecr_repository" "app" {
  name                 = "inframanager"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.tags
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}
