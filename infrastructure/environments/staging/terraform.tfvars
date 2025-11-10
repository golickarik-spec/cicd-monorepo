# Staging Environment Configuration
project_name = "cicd"
aws_region   = "us-east-1"

# Network Configuration
vpc_cidr = "10.1.0.0/16"

# Database Configuration
mysql_db       = "appdb_staging"
mysql_user     = "appuser"
# mysql_password - Set via environment variable TF_VAR_mysql_password

# Backend Configuration
backend_cpu    = 512
backend_memory = 1024

# Image tag - Will be set by CI/CD
image_tag = "staging"


