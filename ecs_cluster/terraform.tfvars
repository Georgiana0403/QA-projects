app_name = "project"

ecs_services = {
  frontend = {
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

