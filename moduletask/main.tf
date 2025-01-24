terraform {
  backend "s3" {
    bucket         = "tf19"                    # Name of your S3 bucket
    key            = "terraform" # Path within the bucket to store the state file
    region         = "ca-central-1"            # Replace with your bucket's AWS region
    encrypt        = true                      # Enable encryption at rest
  }
}

provider "aws" {
  region = "ca-central-1"  # Make sure this is the region you're working in
}

module "vpc" {
  source       = "./modules/vpc"
  vpc_cidr     = "10.0.0.0/16"
  azs          = ["ca-central-1a", "ca-central-1b"]
  vpc_name     = "MyVPC"
}

module "security_groups" {
  source            = "./modules/sg" # Path to your security group module
  vpc_id            = module.vpc.vpc_id
  sg_name           = "DynaicSG"
  allowed_ports     = [22, 80, 443, 3306] # SSH, HTTP, HTTPS, MySQL
  ingress_cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere
  egress_cidr_blocks  = ["0.0.0.0/0"] # Allow to anywhere
}


module "ec2" {
  source         = "./modules/ec2"
  ami            = "ami-0956b8dc6ddc445ec"
  instance_type  = "t2.micro"
  subnet_ids     = module.vpc.public_subnets
  instance_count = 2
  security_group_ids = [module.security_groups.security_group_id]
  user_data      = "#!/bin/bash\nsudo yum install -y nginx"
}
