variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ECS"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
}

variable "desired_size" {
  description = "Desired number of instances"
  type        = number
}

variable "task_execution_role_arn" {
  description = "ARN of the task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
}

variable "alb_target_group_backend_arn" {
  description = "ARN of the backend target group"
  type        = string
}

variable "alb_target_group_frontend_arn" {
  description = "ARN of the frontend target group"
  type        = string
}

variable "alb_target_group_qdrant_arn" {
  description = "ARN of the Qdrant target group"
  type        = string
}

# ECR Repository URLs
variable "backend_repository_url" {
  description = "URL of the backend ECR repository"
  type        = string
}

variable "ai_service_repository_url" {
  description = "URL of the AI service ECR repository"
  type        = string
}

variable "frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the ECS instance profile"
  type        = string
}

variable "backend_secrets_arn" {
  description = "ARN of the backend secrets in AWS Secrets Manager"
  type        = string
  default     = ""
}

variable "cloudwatch_log_kms_key_id" {
  description = "KMS key ID for CloudWatch log encryption"
  type        = string
  default     = null
}