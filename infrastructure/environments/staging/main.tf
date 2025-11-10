terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Optional: Configure S3 backend for state management
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "cicd/staging/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "staging"
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  environment = "staging"
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
  }
}

############################
# Networking
############################
module "networking" {
  source = "../../modules/networking"

  project_name    = "${var.project_name}-${local.environment}"
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  tags            = local.common_tags
}

############################
# Security
############################
module "security" {
  source = "../../modules/security"

  project_name = "${var.project_name}-${local.environment}"
  vpc_id       = module.networking.vpc_id
  backend_port = var.backend_port
  tags         = local.common_tags
}

############################
# RDS
############################
module "rds" {
  source = "../../modules/rds"

  project_name           = "${var.project_name}-${local.environment}"
  private_subnet_ids     = module.networking.private_subnet_ids
  security_group_id      = module.security.rds_security_group_id
  mysql_db               = var.mysql_db
  mysql_user             = var.mysql_user
  mysql_password         = var.mysql_password
  mysql_version          = var.rds_mysql_version
  instance_class         = var.rds_instance_class
  skip_final_snapshot    = false
  deletion_protection    = false
  backup_retention_period = 7
  multi_az               = false
  tags                   = local.common_tags
}

############################
# ECR
############################
module "ecr" {
  source = "../../modules/ecr"

  project_name = "${var.project_name}-${local.environment}"
  scan_on_push = true
  tags         = local.common_tags
}

############################
# ECS
############################
module "ecs" {
  source = "../../modules/ecs"

  project_name           = "${var.project_name}-${local.environment}"
  aws_region             = var.aws_region
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  private_subnet_ids     = module.networking.private_subnet_ids
  alb_security_group_id  = module.security.alb_security_group_id
  ecs_security_group_id  = module.security.ecs_security_group_id
  backend_image_url      = module.ecr.backend_repository_url
  image_tag              = var.image_tag
  backend_port           = var.backend_port
  backend_cpu            = var.backend_cpu
  backend_memory         = var.backend_memory
  desired_count          = 2
  db_host                = module.rds.rds_endpoint
  db_user                = var.mysql_user
  db_password            = var.mysql_password
  db_name                = var.mysql_db
  log_retention_days     = 14
  enable_container_insights = true
  tags                   = local.common_tags
}

############################
# S3 + CloudFront
############################
module "s3_cloudfront" {
  source = "../../modules/s3-cloudfront"

  project_name          = "${var.project_name}-${local.environment}"
  enable_versioning     = true
  cloudfront_price_class = "PriceClass_100"
  tags                  = local.common_tags
}


