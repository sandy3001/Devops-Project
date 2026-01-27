variable "aws_region" {
  default = "us-east-1"
}

variable "project" {
  default = "simple-infra"
}

variable "environment" {
  description = "Environment name (dev | prod)"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "db_name" {
  default = "appdb"
}
