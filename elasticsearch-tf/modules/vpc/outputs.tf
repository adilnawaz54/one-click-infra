output "vpc_id" {
  value = aws_vpc.main.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}

output "elasticsearch_sg_id" {
  value = aws_security_group.elasticsearch_sg.id
}
