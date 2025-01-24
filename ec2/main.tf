provider "aws" {
  region = "us-east-1"
}
resource "aws_instance" "example" {
  count         = 3 # Number of instances to create
  ami           = "ami-04b4f1a9cf54c11d0" 
  instance_type = "t2.micro"

  tags = {
    Name = "example-instance-${count.index + 1}"
  }
}
