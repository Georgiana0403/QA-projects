provider "aws" {
  region = "eu-central-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.58.0"
    }
  }
  required_version = ">= 1.0"
}

# Data
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}
# VPC Resources
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnets" {
  count             = 2
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_subnet" "private_subnets" {
  count             = 2
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
locals {
  public_subnet_ids  = aws_subnet.public_subnets[*].id
  private_subnet_ids = aws_subnet.private_subnets[*].id
}


# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  count = 2
  tags = {
    Name = "${var.app_name}-nat-eip-${count.index + 1}"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "nat_gw" {
  count         = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = {
    Name = "${var.app_name}-nat-gw-${count.index + 1}"
  }
}

# Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.app_name}-public-route-table"
  }
}

# Public Subnet Associations
resource "aws_route_table_association" "public_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Private Route Tables
resource "aws_route_table" "private_route_tables" {
  count  = 2
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    Name = "${var.app_name}-private-route-table-${count.index + 1}"
  }
}

# Private Subnet Associations
resource "aws_route_table_association" "private_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_tables[count.index].id
}

resource "aws_lb" "main" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_subnets[*].id
  enable_deletion_protection = false
}
locals {
  internal_alb_dns = aws_lb.main.dns_name
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.app_name}-alb-security-group"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main_vpc.id

  # Inbound rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-alb-security-group"
  }
}
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.main.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
# Security Group
resource "aws_security_group" "ecs_sg" {
  name        = "${var.app_name}-ecs-security-group"
  description = "Security group for ECS cluster"
  vpc_id      = aws_vpc.main_vpc.id

  # Inbound rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080  # Backend port
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-ecs-security-group"
  }
}


resource "aws_lb_target_group" "frontend" {
  name        = "frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"
  health_check {
    path                = "/health"  # Adjust to your application's health check endpoint
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 60
    interval            = 300
    matcher             = "200-399"  # Expected HTTP status codes
  }
}

resource "aws_lb_target_group" "backend" {
  name        = "backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"
}

# Resources
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_ecr_repository" "frontend" {
  name = "frontend"
}

resource "aws_ecr_repository" "backend" {
  name = "backend"
}
resource "aws_ecs_cluster" "ecs_cluster" {
  name = lower("${var.app_name}-cluster")
}

# ECS Services
resource "aws_ecs_service" "service" {
  for_each = var.ecs_services
  name            = "${each.key}-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition[each.key].arn
  launch_type     = "FARGATE"
  desired_count   = each.value.desired_count
  network_configuration {
    subnets          = each.value.is_public == true ? local.public_subnet_ids : local.private_subnet_ids
    assign_public_ip = each.value.is_public
    security_groups  = [aws_security_group.ecs_sg.id]
  }
  load_balancer {
    target_group_arn = each.key == "frontend" ? aws_lb_target_group.frontend.arn : aws_lb_target_group.backend.arn
    container_name   = each.key
    container_port   = each.value.container_port
  }
}
# ECS Task Definitions
resource "aws_ecs_task_definition" "ecs_task_definition" {
  for_each = var.ecs_services
  family                   = "${lower(var.app_name)}-${each.key}"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = each.value.memory
  cpu                      = each.value.cpu
  container_definitions = jsonencode([
    {
      name      = each.key
      image     = var.container_images[each.key]
      cpu       = each.value.cpu
      memory    = each.value.memory
      essential = true
      environment = each.key == "frontend" ? [
      { 
        name = "BACKEND_URL", 
        value = "http://${local.internal_alb_dns}/backend" 
      }
      ] : [],
      portMappings = [
        {
          containerPort = each.value.container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "${lower(each.key)}-logs"
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = var.app_name
        }
      }
    }
  ])
}
# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "ecs_cw_log_group" {
  for_each = toset(keys(var.ecs_services))
  name     = lower("${each.key}-logs")
}

# ECS Auto Scaling Configuration
resource "aws_appautoscaling_target" "service_autoscaling" {
  for_each = var.ecs_services
  max_capacity       = each.value.auto_scaling.max_capacity
  min_capacity       = each.value.auto_scaling.min_capacity
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.service[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policies
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  for_each = var.ecs_services
  name               = "${var.app_name}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service_autoscaling[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.service_autoscaling[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.service_autoscaling[each.key].service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = each.value.auto_scaling.memory_threshold
  }
}
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  for_each = var.ecs_services
  name               = "${var.app_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service_autoscaling[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.service_autoscaling[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.service_autoscaling[each.key].service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = each.value.auto_scaling.cpu_threshold
  }
}
