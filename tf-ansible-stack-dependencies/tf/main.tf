terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-2"
}
=======
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
# Define EC2 instances (4 instances)
# --------------------------------------------------
locals {
  instances = {
    instance1 = {
      ami           = data.aws_ami.ubuntu.id
      instance_type = "t3.micro"
    }
    instance2 = {
      ami           = data.aws_ami.ubuntu.id
      instance_type = "t3.micro"
    }
  }
}

# --------------------------------------------------
# Create AWS Key Pair using Spacelift-mounted public key
# --------------------------------------------------
resource "aws_key_pair" "ssh_key" {
  key_name   = "ec2"
  public_key = file(var.public_key)
}

# --------------------------------------------------
# Create EC2 instances
# --------------------------------------------------
resource "aws_instance" "this" {
  for_each                    = local.instances
  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  key_name                    = aws_key_pair.ssh_key.key_name
  associate_public_ip_address = true

  tags = {
    Name = each.key
  }
}
