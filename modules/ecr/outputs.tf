output "backend_repository_url" {
  description = "URL of the backend ECR repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "backend_repository_arn" {
  description = "ARN of the backend ECR repository"
  value       = aws_ecr_repository.backend.arn
}

output "ai_service_repository_url" {
  description = "URL of the AI service ECR repository"
  value       = aws_ecr_repository.ai_service.repository_url
}

output "ai_service_repository_arn" {
  description = "ARN of the AI service ECR repository"
  value       = aws_ecr_repository.ai_service.arn
}

output "frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}

output "frontend_repository_arn" {
  description = "ARN of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.arn
}

output "all_repository_urls" {
  description = "Map of all ECR repository URLs"
  value = {
    backend    = aws_ecr_repository.backend.repository_url
    ai_service = aws_ecr_repository.ai_service.repository_url
    frontend   = aws_ecr_repository.frontend.repository_url
  }
}