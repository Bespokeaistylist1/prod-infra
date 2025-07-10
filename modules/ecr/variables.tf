variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}