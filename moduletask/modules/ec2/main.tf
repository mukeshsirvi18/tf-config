resource "aws_instance" "ec2" {
  count         = var.instance_count
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = element(var.subnet_ids, count.index)
  vpc_security_group_ids = var.security_group_ids

  user_data = var.user_data

  tags = {
    Name = "${var.instance_name}-${count.index + 1}"
  }
}
