provider "aws" {
  region = "eu-north-1"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "flask_sg" {
  name        = "flask_sg"
  description = "Allow port 80 inbound traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "flask_eip" {
  instance = aws_instance.flask_app.id
  vpc      = true
}


resource "aws_instance" "flask_app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.flask_sg.id]
  associate_public_ip_address = true


  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 git
              pip3 install flask
              git clone https://github.com/kumarsunny01912/sample_flask.git /home/ec2-user/app
              cd /home/ec2-user/app
              nohup python3 app.py > output.log 2>&1 &
              EOF

  tags = {
    Name = "FlaskAppInstance"
  }
}
