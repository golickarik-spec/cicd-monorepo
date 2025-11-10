# Development Environment Configuration
project_name = "cicd"
aws_region   = "us-east-1"

# Network Configuration
vpc_cidr = "10.0.0.0/16"

# Database Configuration
mysql_db       = "appdb_dev"
mysql_user     = "appuser"
# mysql_password - Set via environment variable TF_VAR_mysql_password

# Backend Configuration
backend_cpu    = 256
backend_memory = 512

# Image tag - Will be set by CI/CD
image_tag = "latest"


