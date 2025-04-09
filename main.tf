provider "aws" {
  region = "ap-southeast-3"
}

resource "aws_key_pair" "poc_mcp" {
  key_name   = "poc-mcp"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "ollama_sg" {
  name        = "ollama-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Ollama HTTP port"
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_spot_instance_request" "ollama_spot" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.poc_mcp.key_name
  vpc_security_group_ids = [aws_security_group.ollama_sg.id]

  spot_price           = var.spot_price
  wait_for_fulfillment = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y

              # Install Podman
              yum install -y podman
              systemctl enable podman
              systemctl start podman || true
              podman info || echo "Podman is not running properly"

              # Install Ollama
              curl -fsSL https://ollama.com/install.sh | sh

              sleep 10
              OLLAMA_HOST=0.0.0.0 ollama pull deepseek-coder:6.7b
              OLLAMA_HOST=0.0.0.0 nohup ollama serve > ~/ollama.log 2>&1 &
              EOF
  tags = {
    Name = "olla-poc"
  }
}
