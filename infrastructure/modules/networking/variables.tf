variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnets with CIDR and AZ"
  type        = map(object({ cidr = string, az = string }))
}

variable "private_subnets" {
  description = "Map of private subnets with CIDR and AZ"
  type        = map(object({ cidr = string, az = string }))
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}


