resource "aws_db_subnet_group" "postgres" {
  name = "main-infra-postgres-subnet-group"

  subnet_ids = [
    var.private_subnet_id,
    var.private_subnet_2_id
  ]

  tags = {
    Name = "main-infra-postgres-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "main-infra-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"

  db_name  = "appdb"
  username = "appadmin"

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = 1

  tags = {
    Name = "main-infra-postgres"
  }
}