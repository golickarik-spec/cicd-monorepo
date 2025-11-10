output "alb_security_group_id" {
  description = "ID of ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "ecs_security_group_id" {
  description = "ID of ECS security group"
  value       = aws_security_group.ecs_sg.id
}

output "rds_security_group_id" {
  description = "ID of RDS security group"
  value       = aws_security_group.rds_sg.id
}


