# 📚 Infrastructure Documentation

This directory contains comprehensive documentation for the ECS Production Infrastructure.

## 📁 Files

### 🎨 Interactive Diagrams
- **[deployment-diagram.html](./deployment-diagram.html)** - Interactive deployment flow diagram with drag-and-drop components

## 🚀 How to Use the Interactive Diagram

### Opening the Diagram
1. Open `deployment-diagram.html` in any modern web browser
2. The diagram will load with all infrastructure components visible
3. Use the navigation controls to explore the architecture

### Navigation Controls
- **🖱️ Drag Canvas**: Click and drag the background to pan around the diagram
- **📦 Move Components**: Click and drag individual components to rearrange them
- **🔍 Zoom**: Use the zoom controls in the bottom-left corner
- **⌨️ Keyboard Shortcuts**:
  - `+` or `=` : Zoom in
  - `-` : Zoom out
  - `0` : Reset zoom
  - `c` : Center view

### Mobile Support
- **📱 Touch Gestures**: 
  - Single finger drag to pan
  - Pinch to zoom in/out
  - Tap components for details

## 🏗️ Architecture Overview

The diagram shows the complete deployment flow of our ECS-based infrastructure:

### 🌐 Network Layer
- **VPC**: 10.0.0.0/16 with public and private subnets across 2 AZs
- **Load Balancer**: Application Load Balancer for traffic distribution
- **Security Groups**: Layered security with specific port access

### 🐳 Container Services
- **Frontend Service**: React/Next.js application (Port 3000)
- **Backend Service**: Node.js/Express API (Port 5001)  
- **AI Service**: Python Flask/FastAPI for ML processing (Port 8000)
- **Redis**: In-memory cache and session store (Port 6379)
- **Qdrant**: Vector database for AI embeddings (Port 6333)

### 💾 Storage & Data
- **EFS**: Persistent file system for Qdrant data
- **ECR**: Container image repositories
- **MongoDB Atlas**: External document database
- **Secrets Manager**: Encrypted credential storage

### 🔒 Security & Access
- **IAM Roles**: Least-privilege access control
- **Security Groups**: Network-level security
- **SSL/TLS**: End-to-end encryption

### 📊 Monitoring & Logging
- **CloudWatch**: Container insights and log aggregation
- **Health Checks**: Application-level monitoring
- **Service Discovery**: Internal service communication

## 🎯 Deployment Flow

The diagram illustrates the 4-step deployment process:

1. **🔧 Initialize Infrastructure**: Terraform setup and validation
2. **🏗️ Build Infrastructure**: VPC, security groups, and load balancer creation
3. **🚢 Deploy Services**: Container deployment and service startup
4. **✅ Verify Deployment**: Health checks and endpoint testing

## 🎨 Component Color Coding

- **🟠 Orange**: AWS Core Services (ALB, ECS, ECR, EFS)
- **🟢 Green**: ECS Services (Frontend, Backend, AI)
- **🔵 Blue**: Network Components (VPC, Security Groups)
- **🟣 Purple**: Database/Storage (Redis, Qdrant, EFS)
- **🔴 Red**: Security Components (IAM, Secrets Manager)
- **🟣 Dark Purple**: Deployment Steps
- **⚫ Gray**: External Services

## 🔄 Traffic Flow

The diagram shows how traffic flows through the system:

1. **Internet** → **ALB** (HTTPS/HTTP)
2. **ALB** → **ECS Services** (Load balanced)
3. **Services** → **Internal Dependencies** (Service discovery)
4. **Services** → **External APIs** (MongoDB, AI APIs)

## 🔧 Customization

The diagram is fully interactive and customizable:
- Move components to match your preferred layout
- Zoom to focus on specific areas
- Use on any device (desktop, tablet, mobile)

## 📱 Browser Compatibility

The diagram works on all modern browsers:
- ✅ Chrome 80+
- ✅ Firefox 75+
- ✅ Safari 13+
- ✅ Edge 80+

## 💡 Tips for Best Experience

1. **Start with Overview**: Begin with the reset/center view to see the full architecture
2. **Focus Areas**: Zoom into specific areas like the ECS cluster or network layer
3. **Follow the Flow**: Use the numbered deployment steps to understand the process
4. **Interactive Learning**: Move components around to better understand relationships
5. **Mobile Viewing**: Use landscape mode on mobile devices for better visibility

## 🔄 Updates

This documentation is updated whenever infrastructure changes are made. The interactive diagram reflects the current state of the production infrastructure.

---

For technical questions about the infrastructure, refer to the main [README.md](../README.md) in the project root.
