# Project Configuration
project_name = "prod-infra"
environment  = "production"
aws_region   = "ap-south-1"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

# ECS Configuration
ecs_instance_type = "t3.small"
ecs_min_size      = 1
ecs_max_size      = 5
ecs_desired_size  = 2

# DNS Configuration
# Set enable_dns = true and domain_name = "yourdomain.com" to enable DNS
enable_dns         = false
domain_name        = ""
create_hosted_zone = true

# Custom subdomains - add your subdomain here
custom_subdomains = [
  # Example: uncomment and modify as needed
  # { name = "app", type = "A" },
  # { name = "blog", type = "A" },
  # { name = "shop", type = "A" }
]