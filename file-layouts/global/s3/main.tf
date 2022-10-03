provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = "${aws_s3_bucket.terraform_state_bucket.bucket}"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = "${aws_s3_bucket.terraform_state_bucket.id}"
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "terraform-state-track-2022"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name = "terraform-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-state-track-2022"
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
}