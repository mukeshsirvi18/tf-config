variable "ami" {
  description = "AMI ID to use for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the EC2 instances"
  default     = "t2.micro"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EC2 instances"
  type        = list(string)
}

variable "instance_count" {
  description = "The number of EC2 instances to create"
  default     = 1
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instances"
  type        = list(string)
}

variable "user_data" {
  description = "User data script to run on EC2 instances"
  type        = string
  default     = ""
}

variable "instance_name" {
  description = "Base name for EC2 instances"
  default     = "EC2Instance"
}
