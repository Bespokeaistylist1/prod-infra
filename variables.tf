variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "prod-infra"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "ecs_instance_type" {
  description = "EC2 instance type for ECS cluster"
  type        = string
  default     = "t3.medium"
}

variable "ecs_min_size" {
  description = "Minimum number of instances in ECS cluster"
  type        = number
  default     = 1
}

variable "ecs_max_size" {
  description = "Maximum number of instances in ECS cluster"
  type        = number
  default     = 5
}

variable "ecs_desired_size" {
  description = "Desired number of instances in ECS cluster"
  type        = number
  default     = 2
}