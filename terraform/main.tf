####################
# VPC
####################
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "${var.project}-vpc"
    Environment = var.environment
  }
}

####################
# Subnet
####################
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public-subnet"
  }
}

####################
# EC2
####################
resource "aws_instance" "app" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "app-server"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_vpc.main
  ]
}

####################
# RDS
####################
resource "aws_db_instance" "db" {
  identifier        = "app-db"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["password"]

  skip_final_snapshot = true

  tags = {
    Environment = var.environment
  }
}

####################
# S3
####################
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.project}-${var.environment}-bucket"

  tags = {
    Environment = var.environment
  }
}
