resource "random_password" "rds_password" {
  length  = 32
  special = false
}

resource "aws_db_subnet_group" "rds" {
  name = "homelab-rds-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "homelab-rds-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "homelab-rds-sg"
  description = "Allow access to RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block, "100.64.0.0/10"]
    security_groups = [aws_security_group.ec2.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "homelab-postgres"
  engine                 = "postgres"
  engine_version         = "17.5"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 50
  db_name                = "homelabdb"
  username               = "postgres"
  password               = random_password.rds_password.result
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true

  tags = {
    Name = "homelab-rds-instance"
  }
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "homelab/postgres/credentials"
}

resource "aws_secretsmanager_secret_version" "rds_credentials_val" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    dbname   = aws_db_instance.postgres.db_name
    username = aws_db_instance.postgres.username
    password = random_password.rds_password.result
  })
}