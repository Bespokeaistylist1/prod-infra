output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "backend_service_name" {
  description = "Name of the backend service"
  value       = module.ecs.backend_service_name
}

output "ai_service_name" {
  description = "Name of the AI service"
  value       = module.ecs.ai_service_name
}

output "frontend_service_name" {
  description = "Name of the frontend service"
  value       = module.ecs.frontend_service_name
}

# ECR Repository URLs
output "backend_repository_url" {
  description = "URL of the backend ECR repository"
  value       = module.ecr.backend_repository_url
}

output "ai_service_repository_url" {
  description = "URL of the AI service ECR repository"
  value       = module.ecr.ai_service_repository_url
}

output "frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = module.ecr.frontend_repository_url
}

output "all_repository_urls" {
  description = "Map of all ECR repository URLs"
  value       = module.ecr.all_repository_urls
}