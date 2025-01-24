provider "aws" {
  region = "ca-central-1"
}

# Variables
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "azs" {
  default = ["ca-central-1a", "ca-central-1b"]
}

variable "ami_nginx" {
  default = "ami-0956b8dc6ddc445ec" # Replace with the correct AMI ID for your region
}

variable "ami_mysql" {
  default = "ami-0956b8dc6ddc445ec" # Replace with the correct AMI ID for your region
}

variable "instance_type" {
  default = "t2.micro"
}

# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MainVPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "MainIGW"
  }
}

# Create NAT Gateway and Elastic IP
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "NAT-EIP"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "MainNATGateway"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnets" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 3, count.index)
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet-${count.index + 1}"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnets" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 3, count.index + length(var.azs))
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "PrivateSubnet-${count.index + 1}"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public_rta" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "PrivateRouteTable"
  }
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private_rta" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Security Groups
resource "aws_security_group" "public_sg" {
  name        = "PublicSecurityGroup"
  vpc_id      = aws_vpc.main_vpc.id

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
    Name = "PublicSG"
  }
}

resource "aws_security_group" "private_sg" {
  name        = "PrivateSecurityGroup"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = aws_subnet.public_subnets[*].cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrivateSG"
  }
}

# Public EC2 Instances
resource "aws_instance" "public_ec2" {
  count         = 3
  ami           = var.ami_nginx
  instance_type = var.instance_type
  subnet_id     = element(aws_subnet.public_subnets[*].id, count.index)
  vpc_security_group_ids = [
    aws_security_group.public_sg.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF

  tags = {
    Name = "PublicEC2-${count.index + 1}"
  }
}

# Private EC2 Instances
resource "aws_instance" "private_ec2" {
  count         = 3
  ami           = var.ami_mysql
  instance_type = var.instance_type
  subnet_id     = element(aws_subnet.private_subnets[*].id, count.index)
  vpc_security_group_ids = [
    aws_security_group.private_sg.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update
              sudo yum install -y mysql-server
              sudo systemctl start mysql
              EOF

  tags = {
    Name = "PrivateEC2-${count.index + 1}"
  }
}

