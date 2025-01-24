variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "The availability zones in which to create subnets"
  type        = list(string)
  default     = ["ca-central-1a", "ca-central-1b"]
}

variable "vpc_name" {
  description = "The name of the VPC"
  default     = "MainVPC"
}

variable "nat_gateway_id" {
  description = "ID of the NAT gateway, if used"
  type        = string
  default     = ""
}
