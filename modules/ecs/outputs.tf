output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "backend_service_name" {
  description = "Name of the backend service"
  value       = aws_ecs_service.backend.name
}

output "ai_service_name" {
  description = "Name of the AI service"
  value       = aws_ecs_service.ai_service.name
}

output "frontend_service_name" {
  description = "Name of the frontend service"
  value       = aws_ecs_service.frontend.name
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs.name
}