terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# --------------------------------------------------
# Fetch latest Ubuntu 22.04 (Jammy) AMI
# --------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"] # Canonical
}

# --------------------------------------------------
# EC2 Instance Definitions
# --------------------------------------------------
locals {
  instances = {
    instance1 = {
      instance_type = "t3.micro"
    }
    instance2 = {
      instance_type = "t3.micro"
    }
  }
}

# --------------------------------------------------
# Security Group (Explicit – Best Practice)
# --------------------------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-ssh-sg"
  description = "Allow SSH access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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

# --------------------------------------------------
# SSH Key Pair (Spacelift-safe)
# --------------------------------------------------
resource "aws_key_pair" "ssh_key" {
  key_name   = "ec2-demo"
  public_key = var.public_key
}

# --------------------------------------------------
# EC2 Instances
# --------------------------------------------------
resource "aws_instance" "this" {
  for_each = local.instances

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = each.value.instance_type
  key_name                    = aws_key_pair.ssh_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]

  tags = {
    Name = each.key
  }
}
