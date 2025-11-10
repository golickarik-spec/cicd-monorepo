############################
# RDS Module
############################

resource "aws_db_subnet_group" "rds" {
  name       = "${var.project_name}-rds-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${var.project_name}-rds-subnets" })
}

resource "aws_db_instance" "mysql" {
  identifier             = "${var.project_name}-mysql"
  engine                 = "mysql"
  engine_version         = var.mysql_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  username               = var.mysql_user
  password               = var.mysql_password
  db_name                = var.mysql_db
  port                   = 3306
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [var.security_group_id]
  skip_final_snapshot    = var.skip_final_snapshot
  deletion_protection    = var.deletion_protection
  backup_retention_period = var.backup_retention_period
  multi_az                = var.multi_az

  tags = merge(var.tags, { Name = "${var.project_name}-mysql" })
}


