variable "server_port" {
  type = number
  description = "the port the server will use for HTTP requests"
  default = 8080
}

variable "cluster_name" {
  description = "the name to use for all the cluster resources"
  type = string
}

variable "db_remote_state-bucket" {
  description = "the name of the s3 bucket for the databases remote state"
  type = string
}

variable "db_remote_state_key" {
  description = "the path for the databases remote state in s3"
  type = string
}

variable "instance_type" {
  description = "the type ec2 instances to run(e.g t2.micro)"
  type = string
}

variable "min_size" {
  description = "the minimum number of ec2 instances in the ASG"
  type = number
}

variable "max_size" {
  description = "the maximum number of ec2 instances in the ASG"
  type = number
}