output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.mysql.port
}

output "rds_db_name" {
  description = "Database name"
  value       = aws_db_instance.mysql.db_name
}


