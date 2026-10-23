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
    cidr_blocks = [aws_vpc.main.cidr_block] # Allow access from within the VPC
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
  password               = "${var.rds_password}" # Use the password from Secrets Manager
  # aws_secretsmanager_secret_version.db_password_val.secret_string["password"]
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true

  tags = {
    Name = "homelab-rds-instance"
  }
}