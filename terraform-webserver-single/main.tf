provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "terrababa" {
  ami = "ami-0c55b159cbfafe1f0" 
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.terrababa_sg.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  tags = {
    "Name" = "terrababa-instance-example"
  }
}