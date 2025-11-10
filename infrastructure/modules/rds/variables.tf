variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets for RDS"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "mysql_db" {
  description = "Database name"
  type        = string
}

variable "mysql_user" {
  description = "Database username"
  type        = string
}

variable "mysql_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "mysql_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0.35"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}


