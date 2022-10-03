output "s3_bucker_arn" {
  value = "${aws_s3_bucket.terraform_state_bucket.arn}"
  description = "the ARN of the s3 bucket"
}

output "dynamodb_table_name" {
  value = "${aws_dynamodb_table.terraform_locks.name}"
  description = "the name of the dynamoDB table"
}