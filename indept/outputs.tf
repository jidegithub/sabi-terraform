# output "neo_arn" {
#   value = aws_iam_user.example[0].neo_arn
#   description = "the arn of user neo"
# }

# output "all_arns" {
#   value = aws_iam_user.example[*].arn
#   description = "the arn of all users"
# }

output "map_of_users" {
  value       = aws_iam_user.example
  description = "the arn of all users"
}

output "all_arns" {
  value       = values(aws_iam_user.example)[*].arn
  description = "the arn of all users"
}

output "upper_names" {

}