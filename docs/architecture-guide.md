# 🏗️ Infrastructure Architecture Guide

## 📋 Table of Contents
- [Overview](#overview)
- [Network Architecture](#network-architecture)
- [Container Services](#container-services)
- [Security Architecture](#security-architecture)
- [Data Flow](#data-flow)
- [Deployment Strategy](#deployment-strategy)
- [Scaling & Performance](#scaling--performance)
- [Monitoring & Observability](#monitoring--observability)
- [Disaster Recovery](#disaster-recovery)

## 🌟 Overview

This production infrastructure deploys a modern microservices architecture on AWS ECS with EC2 instances, designed for high availability, scalability, and security.

### Key Characteristics
- **Multi-AZ Deployment**: Spanning 2 availability zones for redundancy
- **Microservices Architecture**: Separate services for frontend, backend, and AI processing
- **Container Orchestration**: ECS with EC2 for reliable container management
- **Auto Scaling**: Automatic scaling based on demand
- **Security First**: Multiple layers of security controls

## 🌐 Network Architecture

### VPC Design
```
VPC: 10.0.0.0/16 (65,536 IP addresses)
├── Public Subnets (ALB, NAT Gateways)
│   ├── 10.0.1.0/24 (AZ-1a) - 256 IPs
│   └── 10.0.2.0/24 (AZ-1b) - 256 IPs
└── Private Subnets (ECS Services)
    ├── 10.0.3.0/24 (AZ-1a) - 256 IPs
    └── 10.0.4.0/24 (AZ-1b) - 256 IPs
```

### Traffic Flow
1. **Internet → ALB** (Public Subnets)
2. **ALB → ECS Services** (Private Subnets)
3. **ECS → External Services** (via NAT Gateways)

### Security Groups
- **ALB-SG**: Ports 80, 443 from Internet
- **ECS-SG**: Application ports from ALB-SG only
- **EFS-SG**: Port 2049 from ECS-SG only

## 🐳 Container Services

### Service Architecture
```
ECS Cluster (prod-infra-production-cluster)
├── Frontend Service (2 tasks)
│   ├── Port: 3000
│   ├── Route: / (default)
│   └── Technology: React/Next.js
├── Backend Service (2 tasks)
│   ├── Port: 5001
│   ├── Route: /api/*
│   └── Technology: Node.js/Express
├── AI Service (1 task)
│   ├── Port: 8000
│   ├── Internal communication
│   └── Technology: Python/Flask
├── Redis (1 task)
│   ├── Port: 6379
│   ├── Internal service discovery
│   └── Technology: Redis 7
└── Qdrant (1 task)
    ├── Port: 6333
    ├── EFS persistent storage
    └── Technology: Qdrant Vector DB
```

### Resource Allocation
| Service | CPU | Memory | Instances | Storage |
|---------|-----|--------|-----------|---------|
| Frontend | 512 | 1024MB | 2 | Ephemeral |
| Backend | 512 | 1024MB | 2 | Ephemeral |
| AI Service | 1024 | 2048MB | 1 | Ephemeral |
| Redis | 256 | 512MB | 1 | Host Volume |
| Qdrant | 512 | 1024MB | 1 | EFS |

### Service Discovery
- **Namespace**: `prod-infra-production.local`
- **Redis**: `redis.prod-infra-production.local:6379`
- **AI Service**: `ai-service.prod-infra-production.local:8000`
- **Qdrant**: `qdrant.prod-infra-production.local:6333`

## 🔒 Security Architecture

### IAM Strategy
```
IAM Roles & Policies
├── ECS Task Execution Role
│   ├── ECR pull permissions
│   ├── CloudWatch logs write
│   └── Secrets Manager read
├── ECS Task Role
│   ├── Application-specific permissions
│   ├── Service-to-service communication
│   └── AWS service access
└── ECS Instance Role
    ├── ECS agent registration
    ├── CloudWatch agent
    └── EFS mount permissions
```

### Secrets Management
- **Backend Secrets**: MongoDB, AWS credentials, API keys
- **AI Service Secrets**: ML API keys, webhook secrets
- **Encryption**: All secrets encrypted at rest
- **Access**: Least privilege principle

### Network Security
- **Private Subnets**: No direct internet access
- **Security Groups**: Restrictive port access
- **SSL/TLS**: End-to-end encryption
- **VPC Endpoints**: Secure AWS service access

## 🔄 Data Flow

### Request Flow
```
Internet Request
    ↓
Application Load Balancer
    ↓
Route Determination
    ├── / → Frontend Service
    ├── /api/* → Backend Service
    └── /qdrant/* → Qdrant Service
    ↓
ECS Service (Auto Scaling)
    ↓
Container Instance
    ↓
Application Response
```

### Internal Communication
```
Backend Service
    ├── Redis Cache (Session, temporary data)
    ├── AI Service (ML processing requests)
    ├── MongoDB Atlas (Persistent data)
    └── External APIs (Third-party services)

AI Service
    ├── Qdrant Vector DB (Embeddings storage)
    ├── External ML APIs (Gemini, Anthropic, etc.)
    └── Backend Webhook (Result notification)
```

### Storage Strategy
- **Ephemeral**: Frontend, Backend, AI Service (stateless)
- **Host Volume**: Redis (local persistence)
- **EFS**: Qdrant (shared persistent storage)
- **External**: MongoDB Atlas (managed database)

## 🚀 Deployment Strategy

### Deployment Pipeline
1. **Code Commit** → Git repository
2. **Build Phase** → Docker images
3. **Push Images** → ECR repositories
4. **Infrastructure** → Terraform apply
5. **Service Update** → ECS rolling deployment
6. **Health Checks** → Verify deployment
7. **Rollback** → If health checks fail

### Rolling Deployment
- **Zero Downtime**: New tasks start before old ones stop
- **Health Checks**: Application and load balancer level
- **Gradual Rollout**: Task-by-task replacement
- **Automatic Rollback**: On health check failures

### Blue-Green Capability
- **Infrastructure**: Can support blue-green deployments
- **Target Groups**: Multiple target groups for gradual traffic shift
- **DNS**: Route 53 for traffic management

## 📈 Scaling & Performance

### Auto Scaling Strategy
```
ECS Auto Scaling
├── Service Level
│   ├── Target Tracking (CPU/Memory)
│   ├── Min: 1 task per service
│   └── Max: 10 tasks per service
└── Cluster Level
    ├── EC2 Auto Scaling Group
    ├── Min: 1 instance
    ├── Max: 5 instances
    └── Target: 100% capacity utilization
```

### Performance Optimization
- **Application Load Balancer**: Intelligent routing
- **ECS Capacity Providers**: Efficient resource utilization
- **Redis Caching**: Reduced database load
- **Container Resource Limits**: Prevent resource starvation
- **Multi-AZ**: Improved latency and availability

### Scaling Triggers
- **CPU Utilization**: > 70% for 2 minutes
- **Memory Utilization**: > 80% for 2 minutes
- **Request Count**: > 1000 requests/minute
- **Response Time**: > 2 seconds average

## 📊 Monitoring & Observability

### CloudWatch Integration
```
Monitoring Stack
├── Container Insights
│   ├── CPU, Memory, Network metrics
│   ├── Service-level metrics
│   └── Cluster-level metrics
├── Application Logs
│   ├── Structured logging
│   ├── 7-day retention
│   └── Real-time streaming
├── Health Checks
│   ├── ALB health checks
│   ├── ECS health checks
│   └── Custom application health
└── Alarms & Notifications
    ├── High CPU/Memory
    ├── Service failures
    └── Infrastructure issues
```

### Key Metrics
- **Service Availability**: > 99.9% uptime
- **Response Time**: < 2 seconds average
- **Error Rate**: < 1% of requests
- **Resource Utilization**: 60-80% target

### Alerting Strategy
- **Critical**: Immediate PagerDuty/SMS
- **Warning**: Email notifications
- **Info**: Dashboard updates only

## 🛡️ Disaster Recovery

### Backup Strategy
- **EFS**: Automatic backups enabled
- **Container Images**: Stored in ECR with versioning
- **Configuration**: Infrastructure as Code (Terraform)
- **Secrets**: Automatic backup in Secrets Manager

### Recovery Procedures
1. **Service Failure**: Auto-replacement by ECS
2. **AZ Failure**: Traffic shifted to healthy AZ
3. **Region Failure**: Manual deployment to secondary region
4. **Data Loss**: Restore from EFS backups

### RTO/RPO Targets
- **Recovery Time Objective (RTO)**: < 30 minutes
- **Recovery Point Objective (RPO)**: < 5 minutes
- **Service Availability**: 99.9% uptime SLA

### Testing Strategy
- **Monthly**: Failure simulation testing
- **Quarterly**: Full disaster recovery drill
- **Annually**: Cross-region failover test

---

## 📞 Support & Maintenance

### Regular Maintenance
- **Weekly**: Security patch reviews
- **Monthly**: Performance optimization
- **Quarterly**: Architecture reviews
- **Annually**: Disaster recovery testing

### Emergency Contacts
- **Infrastructure Team**: On-call rotation
- **AWS Support**: Business support plan
- **Vendor Support**: Direct contacts for critical services

### Documentation Updates
This document is updated with every major infrastructure change and reviewed quarterly for accuracy.
