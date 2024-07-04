resource "aws_instance" "terraform_node" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = file("${path.module}/userdata.sh")

  tags = {
    Name = "terraform_node"
  }
}
