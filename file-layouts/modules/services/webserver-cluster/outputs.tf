output "alb_dns_name" {
  value = aws_lb.terrababa_lb.dns_name
  description = "the domain name of the load balancer"
}

output "dbaddress" {
  value = data.terraform_remote_state.db.outputs.address
  description = "the mysql database url"
}

output "asg_name" {
  value = aws_autoscaling_group.terrababa_asg.name
  description = "the name of the Auto Scaling Group"
}