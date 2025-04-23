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
    values = ["Deep Learning Base OSS Nvidia Driver GPU AMI (Amazon Linux 2023) *"]
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
  //ami                    = "ami-0d2942d2a406a7156"
  instance_type          = var.instance_type
  key_name               = aws_key_pair.poc_mcp.key_name
  vpc_security_group_ids = [aws_security_group.ollama_sg.id]

  spot_price           = var.spot_price
  wait_for_fulfillment = true
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y

              runuser -l ec2-user -c '
                sudo dnf install -y kernel-devel-$(uname -r) gcc dkms make
                curl -O https://us.download.nvidia.com/tesla/535.161.07/NVIDIA-Linux-x86_64-535.161.07.run
                chmod +x NVIDIA-Linux-x86_64-535.161.07.run
                sudo ./NVIDIA-Linux-x86_64-535.161.07.run --silent
                sudo modprobe nvidia
                nvidia-smi || echo "NVIDIA GPU not detected"

                curl -fsSL https://ollama.com/install.sh | sh
                sleep 5

                OLLAMA_HOST=0.0.0.0 nohup sh -c 'ollama serve && ollama run deepseek-r1' > /home/ec2-user/ollama.log 2>&1 &
                docker run -d --name=code-server -e PUID=1000 -e PGID=1000 -e TZ=Etc/UTC -p 80:8443 -v ~/vscode/config:/config --restart unless-stopped lscr.io/linuxserver/code-server:latest

              '
              EOF
  tags = {
    Name = "poc-ollama-mcp"
  }
}
