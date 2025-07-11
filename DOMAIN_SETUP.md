# Domain Configuration Guide

This guide explains how to point your domain from another provider to your AWS Application Load Balancer (ALB).

## Overview

The infrastructure now includes Route 53 DNS management that allows you to:
1. Create a hosted zone in AWS Route 53 for your domain
2. Configure DNS records to point to your ALB
3. Set up subdomains for different services (www, api, ai)

## Configuration Options

### Option 1: Create New Hosted Zone (Recommended)
This creates a new Route 53 hosted zone and provides nameservers to configure at your domain provider.

### Option 2: Use Existing Hosted Zone
If you already have a Route 53 hosted zone, this option uses it.

## Setup Instructions

### Step 1: Enable DNS Configuration

Edit `terraform.tfvars` and set:
```hcl
enable_dns         = true
domain_name        = "yourdomain.com"  # Replace with your actual domain
create_hosted_zone = true              # Set to false if using existing hosted zone
```

### Step 2: Deploy the Infrastructure

```bash
terraform plan
terraform apply
```

### Step 3: Get the Nameservers

After deployment, get the nameservers:
```bash
terraform output name_servers
```

This will output something like:
```
[
  "ns-123.awsdns-12.com",
  "ns-456.awsdns-45.net", 
  "ns-789.awsdns-78.org",
  "ns-012.awsdns-01.co.uk"
]
```

### Step 4: Configure Your Domain Provider

Go to your domain provider (GoDaddy, Namecheap, etc.) and:

1. **Access DNS Management**: Log into your domain provider and find DNS or nameserver settings
2. **Change Nameservers**: Replace the existing nameservers with the AWS nameservers from Step 3
3. **Save Changes**: This can take 24-48 hours to propagate globally

### Step 5: Verify Configuration

After DNS propagation (usually 15 minutes to 2 hours):

```bash
# Check if domain points to ALB
nslookup yourdomain.com

# Test the endpoints
curl http://yourdomain.com          # Frontend
curl http://api.yourdomain.com/api  # Backend API  
curl http://ai.yourdomain.com/ai    # AI Service
```

## DNS Records Created

The configuration automatically creates:

| Record | Type | Points To | Purpose |
|--------|------|-----------|---------|
| yourdomain.com | A (Alias) | ALB | Root domain |
| www.yourdomain.com | A (Alias) | ALB | WWW subdomain |
| api.yourdomain.com | A (Alias) | ALB | API subdomain |
| ai.yourdomain.com | A (Alias) | ALB | AI service subdomain |

## Traffic Routing

With your domain configured, traffic flows as follows:

- `yourdomain.com` → ALB → Frontend Service
- `www.yourdomain.com` → ALB → Frontend Service  
- `api.yourdomain.com/api/*` → ALB → Backend Service
- `ai.yourdomain.com/ai/*` → ALB → AI Service

## SSL/HTTPS Configuration (Optional Next Step)

To enable HTTPS, you'll need to:

1. Request an SSL certificate from AWS Certificate Manager
2. Configure the ALB to use the certificate
3. Add HTTPS listener rules

This can be added as an enhancement to the current setup.

## Troubleshooting

### DNS Not Resolving
- Wait longer (DNS propagation can take up to 48 hours)
- Check nameservers are correctly set at your domain provider
- Use `dig yourdomain.com` to check DNS resolution

### Services Not Accessible
- Verify ALB is healthy: Check AWS Console → EC2 → Load Balancers
- Check ECS services are running: AWS Console → ECS → Clusters
- Verify security groups allow traffic on ports 80/443

### Health Check Failures
- Ensure your applications respond to health check paths
- Backend: `/health` on port 5001
- AI Service: `/health` on port 5000  
- Frontend: `/` on port 3000

## Cost Considerations

- Route 53 hosted zone: $0.50/month
- DNS queries: $0.40 per million queries
- Health checks: $0.50/month per health check

## Commands Reference

```bash
# Get all DNS-related outputs
terraform output domain_name
terraform output hosted_zone_id  
terraform output name_servers
terraform output domain_urls

# Test domain resolution
nslookup yourdomain.com
dig yourdomain.com

# Test endpoints
curl -I http://yourdomain.com
curl -I http://api.yourdomain.com
curl -I http://ai.yourdomain.com
```