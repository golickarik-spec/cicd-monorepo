variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "backend_port" {
  description = "Port for backend service"
  type        = number
  default     = 8000
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}


