# 🚀 Quick Deployment Guide

This guide walks you through deploying the infrastructure using the visual diagram as reference.

## 📋 Prerequisites Checklist

Before starting, ensure you have:
- [ ] AWS CLI configured (`aws configure`)
- [ ] Terraform >= 1.0 installed
- [ ] Docker images built and ready for ECR
- [ ] Domain name (optional, for DNS setup)
- [ ] SSL certificate ARN (optional, for HTTPS)

## 🎯 Step-by-Step Deployment

### Step 1: 🔧 Initialize Infrastructure

**Open the [Interactive Diagram](./deployment-diagram.html) and locate the purple "Initialize Infrastructure" component**

```bash
# Clone and navigate to the repository
cd /path/to/prod-infra

# Initialize Terraform
terraform init

# Validate configuration
terraform validate
```

**What happens**: Terraform downloads required providers and validates your configuration.

### Step 2: ⚙️ Configure Variables

**In the diagram, look at the various service components to understand what you're configuring**

Edit `terraform.tfvars`:
```hcl
# Project Configuration
project_name = "your-project-name"
environment  = "production"

# ECS Configuration
ecs_instance_type = "t3.small"    # See ECS Cluster component
ecs_desired_size  = 2

# DNS Configuration (optional)
enable_dns         = true
domain_name        = "yourdomain.com"
create_hosted_zone = true

# SSL Configuration (optional)
enable_https         = true
certificate_arn      = "arn:aws:acm:ap-south-1:123456789012:certificate/..."
enable_http_redirect = true
```

### Step 3: 🏗️ Plan Infrastructure

**This corresponds to the "Build Infrastructure" step in the diagram**

```bash
# Plan deployment
terraform plan -out=tfplan

# Review the plan output carefully
# You should see resources for:
# - VPC and subnets (blue components)
# - ALB and security groups (orange components)  
# - ECS cluster and services (green components)
# - IAM roles (red components)
```

### Step 4: 🚢 Deploy Infrastructure

**Follow along with the deployment steps shown in the purple numbered components**

```bash
# Apply the infrastructure
terraform apply tfplan

# Wait for deployment (typically 10-15 minutes)
# You can monitor progress in AWS Console
```

**Monitor these resources being created (as shown in diagram)**:
1. VPC and networking components
2. Security groups and IAM roles
3. Application Load Balancer
4. ECS cluster and capacity provider
5. ECS services (Frontend, Backend, AI, Redis, Qdrant)

### Step 5: 📦 Push Container Images

**Look at the ECR components in the diagram - you'll push images here**

```bash
# Get login token
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-south-1.amazonaws.com

# Get repository URLs
terraform output all_repository_urls

# Tag and push your images
docker tag your-frontend:latest <frontend-repo-url>:latest
docker tag your-backend:latest <backend-repo-url>:latest  
docker tag your-ai-service:latest <ai-service-repo-url>:latest

docker push <frontend-repo-url>:latest
docker push <backend-repo-url>:latest
docker push <ai-service-repo-url>:latest
```

### Step 6: ✅ Verify Deployment

**Use the diagram to understand the traffic flow for testing**

```bash
# Get the load balancer URL
terraform output alb_dns_name

# Test the endpoints (follow traffic flow in diagram)
curl http://<alb-dns-name>/              # Frontend (green component)
curl http://<alb-dns-name>/api/health    # Backend API (green component)
curl http://<alb-dns-name>/qdrant/       # Qdrant dashboard (purple component)
```

**Check service health**:
1. AWS Console → ECS → Clusters → Services
2. Verify all services are running
3. Check CloudWatch logs for any errors

## 🎨 Using the Interactive Diagram During Deployment

### Pre-Deployment
1. **Open** `docs/deployment-diagram.html` in your browser
2. **Familiarize** yourself with the component layout
3. **Follow** the numbered deployment steps (purple components)

### During Deployment
1. **Track Progress** by checking AWS Console for each component type
2. **Understand Dependencies** by following the connection lines
3. **Troubleshoot** by focusing on specific areas (zoom in on problem components)

### Post-Deployment
1. **Verify Traffic Flow** using the diagram's traffic arrows
2. **Monitor Services** by understanding the CloudWatch integration
3. **Plan Scaling** by reviewing the auto-scaling components

## 🔍 Troubleshooting with the Diagram

### Service Won't Start
- **Check**: Security groups (red components) - are ports open?
- **Verify**: IAM roles (red components) - do services have necessary permissions?
- **Review**: Task definitions - are images accessible in ECR?

### Load Balancer Issues
- **Examine**: Target group health checks
- **Verify**: Security group rules between ALB and ECS
- **Check**: Service registration in target groups

### Networking Problems
- **Review**: VPC and subnet configuration (blue components)
- **Check**: NAT Gateway connectivity for outbound traffic
- **Verify**: Route table configurations

### Database Connectivity
- **Check**: Service discovery configuration for Redis/Qdrant
- **Verify**: Security group rules for internal communication
- **Review**: EFS mount points for Qdrant storage

## 📊 Monitoring After Deployment

**Reference the CloudWatch component in the diagram**

### Key Metrics to Watch
```bash
# Check service health
aws ecs describe-services --cluster <cluster-name> --services <service-names>

# View logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/"

# Monitor CPU/Memory
# Use CloudWatch dashboard or AWS Console
```

### Health Check URLs
- **Frontend**: `http://<alb-dns>/ `
- **Backend**: `http://<alb-dns>/api/health`
- **Qdrant**: `http://<alb-dns>/qdrant/`

## 🔄 Updating the Infrastructure

### Code Changes
1. **Build** new Docker images
2. **Push** to ECR repositories
3. **Update** ECS services (they'll automatically pull new images)

### Infrastructure Changes
1. **Modify** Terraform files
2. **Plan** changes: `terraform plan`
3. **Apply** changes: `terraform apply`
4. **Use diagram** to understand impact of changes

## 🛡️ Security Best Practices

**Reference the red security components in the diagram**

### Secrets Management
- **Store** sensitive data in AWS Secrets Manager
- **Use** IAM roles for service authentication
- **Rotate** secrets regularly

### Network Security
- **Keep** services in private subnets
- **Use** security groups for network access control
- **Enable** VPC flow logs for monitoring

### Container Security
- **Scan** images for vulnerabilities
- **Use** least privilege IAM policies
- **Monitor** container runtime security

## 📞 Getting Help

### Documentation Resources
1. **Interactive Diagram**: Visual component relationships
2. **Architecture Guide**: Detailed technical specifications  
3. **Main README**: Project overview and setup
4. **Terraform Docs**: Resource-specific documentation

### AWS Resources
- **ECS Console**: Service health and logs
- **CloudWatch**: Metrics and monitoring
- **Systems Manager**: Parameter store and debugging
- **CloudTrail**: API call auditing

---

**💡 Tip**: Keep the interactive diagram open in a separate tab while working with the infrastructure. It provides valuable context for understanding component relationships and troubleshooting issues.
