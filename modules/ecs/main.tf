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
      image     = "nginx:latest"  # Replace with your backend image
      cpu       = 512
      memory    = 1024
      essential = true

      portMappings = [
        {
          containerPort = 5001
          hostPort      = 0
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

      environment =[
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
                "name":"AWS_REGION",
                "valueFrom":"arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:AWS_REGION::"
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
                "name":"TWILIO_MESSAGING_SERVICE_SID",
                "valueFrom":"arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:TWILIO_MESSAGING_SERVICE_SID::"  
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
                  "name": "REDIS_HOST_QUEUE",
                  "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:REDIS_HOST_QUEUE::"
              },
              {
                  "name": "REDIS_PORT_QUEUE",
                  "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:REDIS_PORT_QUEUE::"
              },
              {
                  "name": "REDIS_HOST_WORKER",
                  "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:REDIS_HOST_WORKER::"
              },
              {
                  "name": "REDIS_PORT_WORKER",
                  "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:REDIS_PORT_WORKER::"
              },
              {
                  "name": "AI_STYLIST_BASE_URL",
                  "valueFrom": "arn:aws:secretsmanager:ap-south-1:546158667784:secret:prod-backend-secrets-ZhvqW8:AI_STYLIST_BASE_URL::"
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
      image     = "python:3.9-slim"  # Replace with your AI service image
      cpu       = 1024
      memory    = 2048
      essential = true

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 0
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
          value = "5000"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"]
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

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-${var.environment}-frontend"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "nginx:latest"  # Replace with your frontend image
      cpu       = 512
      memory    = 1024
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 0
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
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "3001"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:80/ || exit 1"]
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

  load_balancer {
    target_group_arn = var.alb_target_group_ai_service_arn
    container_name   = "ai-service"
    container_port   = 5000
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
    container_port   = 80
  }

  depends_on = [aws_ecs_cluster_capacity_providers.main]

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-service"
    Environment = var.environment
  }
}