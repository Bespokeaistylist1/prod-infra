terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  availability_zones = data.aws_availability_zones.available.names
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# IAM Module
module "iam" {
  source = "./modules/iam"
  
  project_name = var.project_name
  environment  = var.environment
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  
  project_name = var.project_name
  environment  = var.environment
  task_execution_role_arn = module.iam.ecs_task_execution_role_arn
}

# Application Load Balancer Module
module "alb" {
  source = "./modules/alb"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_security_group_id
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.ecs_security_group_id
  
  instance_type = var.ecs_instance_type
  min_size      = var.ecs_min_size
  max_size      = var.ecs_max_size
  desired_size  = var.ecs_desired_size
  
  task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn          = module.iam.ecs_task_role_arn
  instance_profile_name   = module.iam.ecs_instance_profile_name
  
  # Load balancer configuration
  alb_target_group_backend_arn    = module.alb.backend_target_group_arn
  alb_target_group_ai_service_arn = module.alb.ai_service_target_group_arn
  alb_target_group_frontend_arn   = module.alb.frontend_target_group_arn
  
  # ECR repository URLs
  backend_repository_url    = module.ecr.backend_repository_url
  ai_service_repository_url = module.ecr.ai_service_repository_url
  frontend_repository_url   = module.ecr.frontend_repository_url
}

# Route 53 Module (conditional based on enable_dns)
module "route53" {
  count  = var.enable_dns && var.domain_name != "" ? 1 : 0
  source = "./modules/route53"
  
  project_name        = var.project_name
  environment         = var.environment
  domain_name         = var.domain_name
  create_hosted_zone  = var.create_hosted_zone
  alb_dns_name        = module.alb.alb_dns_name
  alb_zone_id         = module.alb.alb_zone_id
  custom_subdomains   = var.custom_subdomains
  
  subdomain_records = [
    {
      name = "www"
      type = "A"
    },
    {
      name = "api"
      type = "A"
    },
    {
      name = "ai"
      type = "A"
    }
  ]
}