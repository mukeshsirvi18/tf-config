provider "aws" {
  region = "ca-central-1"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "example"
  cluster_version = "1.31"

  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id     = "vpc-0cdcb9cfa1f3d26ff"
  subnet_ids = ["subnet-071be40bb7e487309", "subnet-085d326e76c93c59d", "subnet-0881e72e39339e388"]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}