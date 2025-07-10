#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}ECS EC2 Production Infrastructure Deployment${NC}"
echo "========================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not configured or credentials are invalid${NC}"
    echo "Please run: aws configure"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    echo "Please install Terraform: https://www.terraform.io/downloads.html"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI configured${NC}"
echo -e "${GREEN}✓ Terraform installed${NC}"

# Get current AWS account and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
echo -e "${YELLOW}Deploying to Account: $ACCOUNT_ID in Region: $REGION${NC}"

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Terraform initialization failed${NC}"
    exit 1
fi

# Validate Terraform configuration
echo -e "${YELLOW}Validating Terraform configuration...${NC}"
terraform validate

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Terraform validation failed${NC}"
    exit 1
fi

# Plan deployment
echo -e "${YELLOW}Planning deployment...${NC}"
terraform plan -out=tfplan

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Terraform planning failed${NC}"
    exit 1
fi

# Ask for confirmation
echo -e "${YELLOW}Do you want to proceed with the deployment? (y/N)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

# Apply deployment
echo -e "${YELLOW}Applying deployment...${NC}"
terraform apply tfplan

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
    echo ""
    echo "Load Balancer DNS:"
    terraform output alb_dns_name
    echo ""
    echo "Your services are now accessible at:"
    ALB_DNS=$(terraform output -raw alb_dns_name)
    echo "  Frontend: http://$ALB_DNS"
    echo "  Backend API: http://$ALB_DNS/api/"
    echo "  AI Service: http://$ALB_DNS/ai/"
    echo ""
    echo "Next steps:"
    echo "1. Update your DNS records to point to the load balancer"
    echo "2. Configure SSL/TLS certificate for HTTPS"
    echo "3. Update container images in the ECS task definitions"
    echo "4. Monitor services in AWS Console"
else
    echo -e "${RED}Error: Deployment failed${NC}"
    exit 1
fi

rm -f tfplan