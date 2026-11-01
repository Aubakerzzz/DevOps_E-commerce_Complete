resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

resource "aws_cloudwatch_log_group" "client" {
  name              = "/ecs/${var.project_name}/client"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "server" {
  name              = "/ecs/${var.project_name}/server"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "mongo" {
  name              = "/ecs/${var.project_name}/mongo"
  retention_in_days = 14
}

resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "client" {
  name        = "${var.project_name}-client-tg"
  port        = 5173
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

resource "aws_lb_target_group" "server" {
  name        = "${var.project_name}-server-tg"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-499"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.client.arn
  }
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.app.arn
  port              = 5000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server.arn
  }
}

# ── Build the mongo connection string once, safely ──
locals {
  mongo_uri = "mongodb://${var.mongo_root_username}:${urlencode(var.mongo_root_password)}@localhost:27017/leyo?authSource=admin"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  volume {
    name = "mongo_data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.mongo.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.mongo.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    # ── 1. mongo ─────────────────────────────────
    {
      name      = "mongo"
      image     = "mongo:7"
      essential = true

      portMappings = [
        {
          containerPort = 27017
          hostPort      = 27017
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "MONGO_INITDB_ROOT_USERNAME", value = var.mongo_root_username },
        { name = "MONGO_INITDB_ROOT_PASSWORD", value = var.mongo_root_password },
        { name = "MONGO_INITDB_DATABASE", value = "leyo" }
      ]

      mountPoints = [
        {
          sourceVolume  = "mongo_data"
          containerPath = "/data/db"
          readOnly      = false
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "mongosh --quiet --eval 'db.adminCommand(\"ping\").ok' || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 5
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.mongo.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },

    # ── 2. server ────────────────────────────────
    {
      name      = "server"
      image     = "${var.dockerhub_username}/${var.project_name}-server:latest"
      essential = true

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "PORT", value = "5000" },
        { name = "MONGODB_URI", value = local.mongo_uri },
        { name = "NODE_ENV", value = "production" }
      ]

      dependsOn = [
        {
          containerName = "mongo"
          condition     = "HEALTHY"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.server.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },

    # ── 3. client ────────────────────────────────
    {
      name      = "client"
      image     = "${var.dockerhub_username}/${var.project_name}-client:latest"
      essential = true

      portMappings = [
        {
          containerPort = 5173
          hostPort      = 5173
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.client.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution,
    aws_iam_role_policy.ecs_task_efs,
    aws_lb_listener.http,
    aws_lb_listener.api,
    aws_efs_mount_target.mongo
  ]
}

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.client.arn
    container_name   = "client"
    container_port   = 5173
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.server.arn
    container_name   = "server"
    container_port   = 5000
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.api,
    aws_iam_role_policy_attachment.ecs_execution,
    aws_iam_role_policy.ecs_task_efs
  ]

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Name = "${var.project_name}-service"
  }
}