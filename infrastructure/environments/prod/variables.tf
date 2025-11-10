variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cicd"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets"
  type        = map(object({ cidr = string, az = string }))
  default = {
    a = { cidr = "10.2.1.0/24", az = "us-east-1a" }
    b = { cidr = "10.2.2.0/24", az = "us-east-1b" }
    c = { cidr = "10.2.3.0/24", az = "us-east-1c" }
  }
}

variable "private_subnets" {
  description = "Map of private subnets"
  type        = map(object({ cidr = string, az = string }))
  default = {
    a = { cidr = "10.2.11.0/24", az = "us-east-1a" }
    b = { cidr = "10.2.12.0/24", az = "us-east-1b" }
    c = { cidr = "10.2.13.0/24", az = "us-east-1c" }
  }
}

variable "backend_port" {
  description = "Backend service port"
  type        = number
  default     = 8000
}

variable "backend_cpu" {
  description = "CPU units for backend task"
  type        = number
  default     = 1024
}

variable "backend_memory" {
  description = "Memory for backend task"
  type        = number
  default     = 2048
}

variable "mysql_db" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "mysql_user" {
  description = "Database username"
  type        = string
  default     = "appuser"
}

variable "mysql_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "rds_mysql_version" {
  description = "MySQL version"
  type        = string
  default     = "8.0.37"
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}


