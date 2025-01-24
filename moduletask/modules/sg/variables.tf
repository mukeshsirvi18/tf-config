variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "sg_name" {
  description = "The name of the security group"
  default     = "MySecurityGroup"
}

variable "allowed_ports" {
  description = "List of ports to allow for ingress"
  type        = list(number)
  default     = [22, 443, 80] # Default ports for SSH, HTTPS, HTTP
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks for ingress rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "egress_cidr_blocks" {
  description = "CIDR blocks for egress rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
