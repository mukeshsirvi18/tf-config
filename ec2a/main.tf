
provider "aws" {
  region = "us-east-1"
}

variable "environment" {
  description = "The environment for the EC2 instance (dev, qa, prod)"
  type        = string
  default     = "dev"
}

variable "ami_id" {
  description = "The AMI ID to use for the instances"
  type        = string
  default     = "ami-04b4f1a9cf54c11d0"
}

variable "instance_type" {
  description = "The instance type to use"
  type        = string
  default     = "t2.micro"
}

# Mapping the number of instances based on the environment
locals {
  instance_count = {
    dev  = 1
    qa   = 2
    prod = 3
  }
  selected_env = "prod"
}

# EC2 Instance Resource
resource "aws_instance" "example" {
  count         = lookup(local.instance_count, local.selected_env, 0) # Default to 0 if environment not found
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name        = "${local.selected_env}-instance-${count.index + 1}"
    Environment = local.selected_env
  }
}
