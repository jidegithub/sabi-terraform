#allow inbound http requests
resource "aws_security_group_rule" "allow_http_inbound-rule_alb" {
  type = "ingress"
  security_group_id = aws_security_group.alb_sg.id
  
  from_port = local.http_port
  to_port   = local.http_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

#allow all outbound requests
resource "aws_security_group_rule" "allow_all_outbound-rule_alb" {
  type = "egress"
  security_group_id = aws_security_group.alb_sg.id

  from_port = local.any_port
  to_port = local.any_port
  protocol = local.any_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_inbound_launch_config" {
  type = "ingress"
  security_group_id = aws_security_group.launch_config_sg.id

  from_port = var.server_port
  to_port   = var.server_port
  protocol = "tcp"
  cidr_blocks = local.all_ips
}

resource "aws_security_group" "launch_config_sg" {
  name = "${var.cluster_name}-launch-config_sg"
}

resource "aws_security_group" "alb_sg" {
  name = "${var.cluster_name}-alb-sg"
}

resource "aws_launch_configuration" "terrababa_launch_config" {
  image_id = "ami-0c55b159cbfafe1f0"
  instance_type = var.instance_type
  security_groups = ["${aws_security_group.launch_config_sg.id}"]
  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "terrababa_asg" {
  launch_configuration = "${aws_launch_configuration.terrababa_launch_config.name}"
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = ["${aws_lb_target_group.terrababa_asg.arn}"]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key = "Name"
    value = "${var.cluster_name}-terrababa-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "terrababa_lb" {
  name = "${var.cluster_name}-terrababa-lb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = ["${aws_security_group.alb_sg.id}"]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.terrababa_lb.arn}"
  port = local.http_port
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_target_group" "terrababa_asg" {
  name = "${var.cluster_name}-lb-target-group"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "terrababa_asg" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.terrababa_asg.arn}"
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address = "${data.terraform_remote_state.db.outputs.address}"
    db_port = "${data.terraform_remote_state.db.outputs.port}"
  }
}

# data "terraform_remote_state" "db" {
#   backend = "s3"

#   config = {
#     bucket = "var.db_remote_state-bucket"
#     key = "var.db_remote_state_key/terraform.tfstate"
#     region = "us-east-2"
#   }
# }

locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

# terraform {
#   backend "s3" {
#     bucket = "var.db_remote_state-bucket"
#     key = "var.db_remote_state_key/terraform.tfstate"
#     region = "us-east-2"

#     dynamodb_table = "terraform-up-and-running-locks"
#     encrypt = true
#   }
# }