resource "aws_instance" "elasticsearch_servers" {
  count                    = length(var.private_subnet_ids)
  ami                      = var.elasticsearch_ami
  instance_type            = var.elasticsearch_instance_type
  subnet_id                = var.private_subnet_ids[count.index]
  vpc_security_group_ids   = [var.elasticsearch_sg_id]
  key_name                 = var.key_name
  tags = {
    Name = "elasticsearch-server-${count.index}"
    Role = "infra-server"
  }
}
