output "cluster_id" {
  description = "ID of ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "Name of ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = aws_lb.alb.dns_name
}

output "alb_arn" {
  description = "ARN of ALB"
  value       = aws_lb.alb.arn
}

output "service_name" {
  description = "Name of ECS service"
  value       = aws_ecs_service.backend.name
}

output "task_definition_arn" {
  description = "ARN of task definition"
  value       = aws_ecs_task_definition.backend.arn
}


