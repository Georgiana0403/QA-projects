variable "app_name" {
  description = "Application Name"
  type        = string
}
variable "region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.10.101.0/24", "10.10.102.0/24"]
}

variable "ecs_services" {
  type = map(object({
    image          = string
    cpu            = number
    memory         = number
    container_port = number
    host_port      = number
    desired_count  = number
    is_public      = bool
    protocol       = string
    auto_scaling = object({
      max_capacity     = number
      min_capacity     = number
      cpu_threshold    = number
      memory_threshold = number
    })
  }))
}

variable "container_images" {
  type = object({
    frontend = string
    backend = string
  })
  default = {
    # Public images that can demonstrate API interactions
    frontend = "paulbouwer/hello-kubernetes:1.10"
    backend = "mendhak/http-https-echo:latest"
  }
}

# New variables for VPC configuration
variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "az_count" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 2
}

# Optional tagging variables
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
