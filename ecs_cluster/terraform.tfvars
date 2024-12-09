app_name = "lab"
ecs_role_arn = "arn:aws:iam::974916147474:role/lab-ecs-task-execution-role"
ecs_services = {
  frontend = {
    image          = "974916147474.dkr.ecr.us-west-2.amazonaws.com/frontend:1.0.0"
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
    image          = "974916147474.dkr.ecr.us-west-2.amazonaws.com/backend:1.0.0"
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
internal_alb_dns = "internal-lab-internal-1346867040.us-west-2.elb.amazonaws.com"
private_subnet_ids = [
  "subnet-07d319bfa097e3f15",
  "subnet-000762dd205df7449"
]
public_subnet_ids = [
  "subnet-07fefa3758be8deb7",
  "subnet-04879c6bf66d4eaa3"
]
security_group_ids = [
  "sg-0906ef96a202c2a5e",
  "sg-039f449b9486424c1"
]
target_group_arns = {
  backend = {
    arn = "arn:aws:elasticloadbalancing:us-west-2:974916147474:targetgroup/backend-tg/28233189510ab43f"
  }
  frontend = {
    arn = "arn:aws:elasticloadbalancing:us-west-2:974916147474:targetgroup/frontend-tg/7d8757b0eae280c5"
  }
}