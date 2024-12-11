app_name = "project-cluster"
ecs_role_arn = "arn:aws:iam::YOUR_ACCOUNT_ID:role/ecs-task-execution-role"
ecs_services = {
  frontend = {
    image          = "YOUR_ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com/frontend:1.0.0"
    cpu            = 256
    memory         = 512
    container_port = 8080
    host_port      = 8080
    desired_count  = 2
    is_public      = true
    protocol       = "HTTP"
    auto_scaling = {
      max_capacity    = 3
      min_capacity    = 2
      cpu_threshold    = 50
      memory_threshold = 50
    }
  }
  backend = {
    image          = "974916147474.dkr.ecr.eu-central-1.amazonaws.com/backend:1.0.0"
    cpu            = 256
    memory         = 512
    container_port = 8080
    host_port      = 8080
    desired_count  = 2
    is_public      = false
    protocol       = "HTTP"
    auto_scaling = {
      max_capacity    = 3
      min_capacity    = 2
      cpu_threshold    = 75
      memory_threshold = 75
    }
  }
}
internal_alb_dns = aws_lb.main.dns_name
private_subnet_ids = [for id in aws_subnet.public_subnets[*].id: id]
public_subnet_ids = [for id in aws_subnet.public_subnets[*].id: id]
security_group_ids = [aws_security_group.ecs_sg.id]
target_group_arns = {
  frontend = {
    arn = aws_lb_target_group.frontend.arn
  },
  backend = {
    arn = aws_lb_target_group.backend.arn
  }
}
