# Data source for ECS optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
    Environment = var.environment
  }
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}-${var.environment}.local"
  description = "Service discovery namespace for ${var.project_name}-${var.environment}"
  vpc         = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-service-discovery"
    Environment = var.environment
  }
}

# Service Discovery Service for Qdrant
resource "aws_service_discovery_service" "qdrant" {
  name = "qdrant"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-qdrant-discovery"
    Environment = var.environment
  }
}

# Service Discovery Service for AI Service
resource "aws_service_discovery_service" "ai_service" {
  name = "ai-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ai-service-discovery"
    Environment = var.environment
  }
}

# Service Discovery Service for Redis
resource "aws_service_discovery_service" "redis" {
  name = "redis"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis-discovery"
    Environment = var.environment
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "main" {
  name = "${var.project_name}-${var.environment}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn

    managed_scaling {
      maximum_scaling_step_size = 5
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-capacity-provider"
    Environment = var.environment
  }
}

# ECS Cluster Capacity Provider
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}

# Launch Template for ECS instances
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project_name}-${var.environment}-ecs-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile {
    name = "${var.project_name}-${var.environment}-ecs-instance-profile"
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name = aws_ecs_cluster.main.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-ecs-instance"
      Environment = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-launch-template"
    Environment = var.environment
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project_name}-${var.environment}-ecs-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_size

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-ecs-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = false
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-${var.environment}-backend"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "ai_service" {
  name              = "/ecs/${var.project_name}-${var.environment}-ai-service"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-ai-service-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-${var.environment}-frontend"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "redis" {
  name              = "/ecs/${var.project_name}-${var.environment}-redis"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis-logs"
    Environment = var.environment
  }
}
resource "aws_cloudwatch_log_group" "qdrant" {
  name              = "/ecs/${var.project_name}-${var.environment}-qdrant"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-qdrant-logs"
    Environment = var.environment
  }
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-${var.environment}-backend"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${var.backend_repository_url}:latest"
      cpu       = 512
      memory    = 1024
      essential = true

      portMappings = [
        {
          containerPort = 5001
          hostPort      = 5001
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      
      environment = [
        {
          name  = "REDIS_HOST"
          value = "redis.${var.project_name}-${var.environment}.local"
        },
        {
          name  = "REDIS_PORT"
          value = "6379"
        },
        {
          name  = "REDIS_URL"
          value = "redis://redis.${var.project_name}-${var.environment}.local:6379"
        },
        {
          name  = "AI_STYLIST_BASE_URL"
          value = "http://ai-service.${var.project_name}-${var.environment}.local:8000"
        }
      ]
      
      secrets = [
        {
          "name": "MONGODB_URI",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:MONGODB_URI::"
        },
        {
          "name": "AWS_ACCESS_KEY_ID",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:AWS_ACCESS_KEY_ID::"
        },
        {
          "name": "AWS_SECRET_ACCESS_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:AWS_SECRET_ACCESS_KEY::"
        },
        {
          "name": "AWS_REGION",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:AWS_REGION::"
        },
        {
          "name": "AWS_S3_BUCKET",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:AWS_S3_BUCKET::"
        },
        {
          "name": "SENDGRID_SENDER_EMAIL",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:SENDGRID_SENDER_EMAIL::"
        },
        {
          "name": "SENDGRID_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:SENDGRID_API_KEY::"
        },
        {
          "name": "TWILIO_ACCOUNT_SID",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:TWILIO_ACCOUNT_SID::"
        },
        {
          "name": "TWILIO_AUTH_TOKEN",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:TWILIO_AUTH_TOKEN::"
        },
        {
          "name": "TWILIO_MESSAGING_SERVICE_SID",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:TWILIO_MESSAGING_SERVICE_SID::"
        },
        {
          "name": "GOOGLE_CLIENT_ID",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:GOOGLE_CLIENT_ID::"
        },
        {
          "name": "GOOGLE_CLIENT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:GOOGLE_CLIENT_SECRET::"
        },
        {
          "name": "FACEBOOK_APP_ID",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:FACEBOOK_APP_ID::"
        },
        {
          "name": "FACEBOOK_APP_SECRET",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:FACEBOOK_APP_SECRET::"
        },
        {
          "name": "APPLE_TEAM_ID",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:APPLE_TEAM_ID::"
        },
        {
          "name": "APPLE_CLIENT_ID",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:APPLE_CLIENT_ID::"
        },
        {
          "name": "APPLE_KEY_ID",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:APPLE_KEY_ID::"
        },
        {
          "name": "APPLE_PRIVATE_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:APPLE_PRIVATE_KEY::"
        },
        {
          "name": "GOOGLE_MAPS_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:GOOGLE_MAPS_API_KEY::"
        },
        {
          "name": "LOCATION_DETAILS_API_URL",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:LOCATION_DETAILS_API_URL::"
        },
        {
          "name": "LOCATION_DETAILS_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:LOCATION_DETAILS_API_KEY::"
        },
        {
          "name": "QUEUE_NAME",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:QUEUE_NAME::"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5001/api || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-task"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "ai_service" {
  family                   = "${var.project_name}-${var.environment}-ai-service"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "ai-service"
      image     = "${var.ai_service_repository_url}:latest"
      cpu       = 1024
      memory    = 2048
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ai_service.name
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        {
          name  = "FLASK_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "8000"
        },
        {
          name  = "QDRANT_PORT"
          value = "6333"
        },
        {
          name  = "QDRANT_HOST"
          value = "http://qdrant.${var.project_name}-${var.environment}.local:6333"
        },
        {
          name = "USE_ENHANCED_IMAGE_ANALYSIS"
          value = "true"
        },
        { 
          name = "USE_ENHANCED_VECTOR_DB"
          value = "true"
        },
        {
          name = "USE_ENHANCED_CHAT"
          value = "true"
        },
        {
          name = "NOTIFICATION_RETRY_ATTEMPTS"
          value = "3"
        },
        {
          name = "NOTIFICATION_TIMEOUT_SECONDS"
          value = "30"
        },
      ]

      "secrets": [

        {
          "name": "GEMINI_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-ai-secrets-RGDgrw:ai-stylist/gemini-api-key:GEMINI_API_KEY::"
        },
        {
          "name": "ANTHROPIC_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-ai-secrets-RGDgrw:ai-stylist/anthropic-api-key:ANTHROPIC_API_KEY::"
        },
        {
          "name": "DEEPSEEK_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-ai-secrets-RGDgrw:ai-stylist/deepseek-api-key:DEEPSEEK_API_KEY::"
        },
        {
          "name": "TOGETHERAI_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-ai-secrets-RGDgrw:ai-stylist/togetherai-api-key:TOGETHERAI_API_KEY::"
        },
        {
          "name": "B_F_L_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-ai-secrets-RGDgrw:ai-stylist/bfl-api-key:B_F_L_API_KEY::"
        },
        {
          "name": "FASHNAI_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-ai-secrets-RGDgrw:ai-stylist/fashnai-api-key:FASHNAI_API_KEY::"
        },
        {
          "name": "WEBHOOK_SECRET",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-ai-secrets-RGDgrw:ai-stylist/webhook-secret:WEBHOOK_SECRET::"
        },
        {
          "name": "QDRANT_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-ai-secrets-RGDgrw:ai-stylist/qdrant-api-key:QDRANT_API_KEY::"
        },
        { "name": "WEBHOOK_BASE_URL",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-ai-secrets-RGDgrw:ai-stylist/webhook-base-url:WEBHOOK_BASE_URL::"
        },
        {
          "name": "BACKEND_WEBHOOK_URL",
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-ai-secrets-RGDgrw:ai-stylist/backend-webhook-url:BACKEND_WEBHOOK_URL::"
        }
      ],

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-ai-service-task"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "qdrant" {
  family                   = "${var.project_name}-${var.environment}-qdrant"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "qdrant"
      image     = "qdrant/qdrant:v0.9.0"
      cpu       = 512
      memory    = 1024
      essential = true

      portMappings = [
        {
          containerPort = 6333
          hostPort      = 6333
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name  = "QDRANT__SERVICE__API_KEY"
          "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-ai-secrets-RGDgrw:ai-stylist/qdrant-api-key:QDRANT_API_KEY::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.qdrant.name
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }

      mountPoints = [
        {
          sourceVolume  = "qdrant-storage"
          containerPath = "/qdrant/storage"
          readOnly      = false
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:6333/readyz || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  volume {
    name = "qdrant-storage"
    efs_volume_configuration {
      file_system_id     = "fs-0a2b490ee8d09efec"
      transit_encryption = "ENABLED"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-qdrant-task"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-${var.environment}-frontend"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${var.frontend_repository_url}:latest"  # Use ECR repository
      cpu       = 512
      memory    = 1024
      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend.name
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
    
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-task"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "redis" {
  family                   = "${var.project_name}-${var.environment}-redis"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "redis"
      image     = "redis:7-alpine"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 6379
          hostPort      = 6379
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.redis.name
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }

      command = [
        "redis-server",
        "--appendonly",
        "yes",
        "--maxmemory",
        "256mb",
        "--maxmemory-policy",
        "allkeys-lru"
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "redis-cli ping || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }

      mountPoints = [
        {
          sourceVolume  = "redis-data"
          containerPath = "/data"
          readOnly      = false
        }
      ]
    }
  ])

  volume {
    name = "redis-data"
    host_path = "/opt/redis-data"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis-task"
    Environment = var.environment
  }
}

# ECS Services
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-${var.environment}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = var.alb_target_group_backend_arn
    container_name   = "backend"
    container_port   = 5001
  }

  depends_on = [aws_ecs_cluster_capacity_providers.main]

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-service"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "ai_service" {
  name            = "${var.project_name}-${var.environment}-ai-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ai_service.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
  }

  service_registries {
    registry_arn = aws_service_discovery_service.ai_service.arn
  }

  depends_on = [aws_ecs_cluster_capacity_providers.main]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ai-service-service"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-${var.environment}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 2

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = var.alb_target_group_frontend_arn
    container_name   = "frontend"
    container_port   = 3000
  }

  depends_on = [aws_ecs_cluster_capacity_providers.main]

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-service"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "redis" {
  name            = "${var.project_name}-${var.environment}-redis"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.redis.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
  }

  service_registries {
    registry_arn = aws_service_discovery_service.redis.arn
  }

  depends_on = [aws_ecs_cluster_capacity_providers.main]

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis-service"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "qdrant" {
  name            = "${var.project_name}-${var.environment}-qdrant"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.qdrant.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
  }

  service_registries {
    registry_arn = aws_service_discovery_service.qdrant.arn
  }

  load_balancer {
    target_group_arn = var.alb_target_group_qdrant_arn
    container_name   = "qdrant"
    container_port   = 6333
  }

  depends_on = [aws_ecs_cluster_capacity_providers.main]

  tags = {
    Name        = "${var.project_name}-${var.environment}-qdrant-service"
    Environment = var.environment
  }
}