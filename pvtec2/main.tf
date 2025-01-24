provider "aws" {
  region = "ca-central-1"
}

# Variables
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_ami" {
  default = "ami-0abcdef1234567890" # Replace with a valid public AMI ID
}

variable "private_ami" {
  default = "ami-0abcdef1234567890" # Replace with a valid private AMI ID
}

variable "instance_type" {
  default = "t2.micro"
}

# Data block to fetch existing VPC
data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["MainVPC"] # Replace with the VPC's name tag
  }
}

# Import existing public subnets
data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main_vpc.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["Public"] # Replace this with the tag identifying public subnets
  }
}

# Import existing private subnets
data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main_vpc.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["Private"] # Replace this with the tag identifying private subnets
  }
}

# Security group for public EC2 instances
resource "aws_security_group" "public_sg" {
  name_prefix = "public-sg-"
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PublicSecurityGroup"
  }
}

# Security group for private EC2 instances
resource "aws_security_group" "private_sg" {
  name_prefix = "private-sg-"
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrivateSecurityGroup"
  }
}

# Public EC2 Instances with Nginx
resource "aws_instance" "public_instances" {
  count         = 3
  ami           = var.public_ami
  instance_type = var.instance_type
  subnet_id     = element(data.aws_subnets.public_subnets.ids, count.index)
  security_groups = [aws_security_group.public_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install nginx -y
              systemctl start nginx
              EOF

  tags = {
    Name = "PublicInstance-${count.index + 1}"
  }
}

# Private EC2 Instances with MySQL
resource "aws_instance" "private_instances" {
  count         = 3
  ami           = var.private_ami
  instance_type = var.instance_type
  subnet_id     = element(data.aws_subnets.private_subnets.ids, count.index)
  security_groups = [aws_security_group.private_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install mysql-server -y
              systemctl start mysql
              EOF

  tags = {
    Name = "PrivateInstance-${count.index + 1}"
  }
}

output "public_ec2_ids" {
  value = aws_instance.public_instances[*].id
}

output "private_ec2_ids" {
  value = aws_instance.private_instances[*].id
}
