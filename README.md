# ECS EC2 Production Infrastructure

This repository contains Terraform configuration for a production-ready ECS EC2 infrastructure setup in AWS ap-south-1 (Mumbai) region.

## Architecture Overview

The infrastructure includes:
- **VPC** with public and private subnets across 2 availability zones
- **Application Load Balancer** for traffic distribution
- **ECS Cluster** with EC2 instances for container orchestration
- **Auto Scaling Group** for automatic scaling
- **Security Groups** for network security
- **IAM Roles** for service permissions
- **CloudWatch Logs** for monitoring

## Services

1. **Backend Service** - API service running on port 3000
2. **AI Service** - ML/AI processing service running on port 5000  
3. **Frontend Service** - Web application running on port 3001

## Traffic Routing

- Default traffic (/) → Frontend Service
- API traffic (/api/*) → Backend Service
- AI traffic (/ai/*) → AI Service

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Docker images for your services pushed to ECR or Docker Hub

## Quick Start

1. **Clone and navigate to the repository**
   ```bash
   cd /path/to/prod-infra
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review and customize variables**
   Edit `terraform.tfvars` to match your requirements:
   - Update container images in `modules/ecs/main.tf`
   - Modify instance types, scaling parameters
   - Adjust VPC CIDR blocks if needed

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure**
   ```bash
   terraform apply
   ```

6. **Get the load balancer URL**
   ```bash
   terraform output alb_dns_name
   ```

## Container Images

Before deployment, update the container images in `modules/ecs/main.tf`:

```hcl
# Backend Service
image = "your-account.dkr.ecr.ap-south-1.amazonaws.com/backend:latest"

# AI Service  
image = "your-account.dkr.ecr.ap-south-1.amazonaws.com/ai-service:latest"

# Frontend Service
image = "your-account.dkr.ecr.ap-south-1.amazonaws.com/frontend:latest"
```

## Scaling Configuration

The infrastructure supports auto-scaling:
- **ECS Services**: Automatically scale based on CPU/memory utilization
- **EC2 Instances**: Auto Scaling Group manages instance count
- **Load Balancer**: Distributes traffic across healthy instances

## Security Features

- Private subnets for ECS instances
- Security groups with minimal required access
- IAM roles with least privilege principles
- VPC with NAT gateways for outbound internet access

## Monitoring

- CloudWatch Container Insights enabled
- Application logs sent to CloudWatch
- Health checks configured for all services

## Customization

### Environment Variables
Add environment variables in the task definitions:
```hcl
environment = [
  {
    name  = "DATABASE_URL"
    value = "your-database-url"
  }
]
```

### Health Checks
Customize health check paths in `modules/alb/main.tf`:
```hcl
health_check {
  path = "/your-health-endpoint"
}
```

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## File Structure

```
├── main.tf                 # Main configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── terraform.tfvars        # Variable values
├── deploy.sh              # Automated deployment script
├── docs/                  # 📚 Documentation directory
│   ├── README.md          # Documentation guide
│   ├── deployment-diagram.html  # 🎨 Interactive architecture diagram
│   └── architecture-guide.md   # 📋 Detailed architecture guide
├── modules/
│   ├── vpc/               # VPC module
│   ├── security-groups/   # Security groups module
│   ├── iam/              # IAM roles module
│   ├── ecr/              # ECR repositories module
│   ├── alb/              # Application Load Balancer module
│   └── ecs/              # ECS cluster and services module
└── README.md             # This file
```

## Documentation

📚 **Comprehensive documentation is available in the `docs/` directory:**

- **[📖 Documentation Guide](./docs/README.md)** - Complete guide to all documentation
- **[🎨 Interactive Architecture Diagram](./docs/deployment-diagram.html)** - Drag-and-drop visual infrastructure overview
- **[📋 Architecture Guide](./docs/architecture-guide.md)** - Detailed technical architecture documentation

### Quick Start with Documentation
1. Open `docs/deployment-diagram.html` in your browser for an interactive overview
2. Use the architecture guide for detailed technical information
3. Refer to the documentation README for navigation help

## Support

For issues or questions:
1. Check Terraform plan output for configuration issues
2. Review CloudWatch logs for application issues
3. Verify security group rules for connectivity issues
4. Check ECS service status in AWS Console