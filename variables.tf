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
  description = "EC2 instance type for ECS"
  type        = string
  default     = "t3.small"
}

variable "ecs_min_size" {
  description = "Minimum number of ECS instances"
  type        = number
  default     = 1
}

variable "ecs_max_size" {
  description = "Maximum number of ECS instances"
  type        = number
  default     = 5
}

variable "ecs_desired_size" {
  description = "Desired number of ECS instances"
  type        = number
  default     = 2
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

# DNS Configuration
variable "domain_name" {
  description = "Domain name to point to the ALB (e.g., example.com)"
  type        = string
  default     = ""
}

variable "create_hosted_zone" {
  description = "Whether to create a Route 53 hosted zone for the domain"
  type        = bool
  default     = true
}

variable "enable_dns" {
  description = "Whether to enable DNS configuration"
  type        = bool
  default     = false
}

variable "custom_subdomains" {
  description = "List of custom subdomain records to create"
  type = list(object({
    name = string
    type = string
  }))
  default = []
}

# SSL/HTTPS Configuration
variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS (from AWS Certificate Manager)"
  type        = string
  default     = ""
}

variable "enable_https" {
  description = "Whether to enable HTTPS listener on port 443"
  type        = bool
  default     = false
}

variable "enable_http_redirect" {
  description = "Whether to redirect HTTP traffic to HTTPS"
  type        = bool
  default     = false
}