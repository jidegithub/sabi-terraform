provider "aws" {
  region = "us-east-2"
}
resource "aws_security_group" "terrababa_sg" {
  name = "terrababa_sg"

  ingress {
    from_port = var.server_port
    to_port   = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "terrababa_alb_sg" {
  name = "application_load_balancer-sg"

  #allow inbound http requests
  ingress {
    from_port = 80
    to_port   = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

#allow all outbound requests
  egress {
    from_port =  0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "terrababa_launch_config" {
  image_id = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.terrababa_sg.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "terrababa_asg" {
  launch_configuration = "${aws_launch_configuration.terrababa_launch_config.name}"
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = ["${aws_lb_target_group.terrababa_asg.arn}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terrababa-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "terrababa_lb" {
  name = "terrababa-lb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = ["${aws_security_group.terrababa_alb_sg.id}"]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.terrababa_lb.arn}"
  port = 80
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
  name = "terrababa-lb-target-group"
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

variable "server_port" {
  type = number
  description = "the port the server will use for HTTP requests"
  default = 8080
}

output "public_ip" {
  value = "${aws_instance.terrababa.public_ip}"
  description = "The public IP of the web server"
}

output "alb_dns_name" {
  value = aws_lb.terrababa_lb.dns_name
  description = "the domain name of the load balancer"
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