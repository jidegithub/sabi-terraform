provider "aws" {
  region = "us-east-2"
}
resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  db_name = "example_database"
  username = "admin"
  password = "gandhiofindia"
  # password = data.aws_secretsmanager_secret_version.db_password.secret_string
  skip_final_snapshot = true
  backup_retention_period = 0
  apply_immediately = true
}

data "aws_secretsmanager_secret" "by_name" {
  name = "db_password"
}

terraform {
  backend "s3" {
    bucket = "terraform-state-track-2022"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
}