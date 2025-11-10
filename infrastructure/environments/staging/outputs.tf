output "backend_alb_url" {
  description = "Backend ALB URL"
  value       = "http://${module.ecs.alb_dns_name}"
}

output "frontend_cdn_url" {
  description = "Frontend CloudFront URL"
  value       = "https://${module.s3_cloudfront.cloudfront_domain_name}"
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.rds_endpoint
  sensitive   = true
}

output "ecr_backend_repository_url" {
  description = "ECR backend repository URL"
  value       = module.ecr.backend_repository_url
}

output "ecr_frontend_repository_url" {
  description = "ECR frontend repository URL"
  value       = module.ecr.frontend_repository_url
}

output "s3_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = module.s3_cloudfront.s3_bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.s3_cloudfront.cloudfront_distribution_id
}


